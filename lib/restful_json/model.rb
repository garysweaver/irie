module RestfulJson

  # TODO: remove this later
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :_as_json_includes, instance_writer: false
      class_attribute :_as_json_excludes, instance_writer: false
      class_attribute :_collected_accepts_nested_attributes_for, instance_writer: false
    end

    module ClassMethods

      # works just like accepts_nested_attributes_for, except it stores any symbols passed in attr_names
      def accepts_nested_attributes_for(*attr_names)
        puts "restful_json's accepts_nested_attributes_for called with attr_names=#{attr_names.inspect}" if ::RestfulJson::Options.debugging?
        
        unless attr_names.nil?
          if attr_names.is_a?(Array)
            attr_names.each do |attr_name|
              self._collected_accepts_nested_attributes_for << attr_name if attr_name.is_a?(Symbol)
            end
          elsif attr_names.is_a?(Symbol)
            self._collected_accepts_nested_attributes_for << attr_name
          end
        end

        puts "collected_accepts_nested_attributes_for = #{collected_accepts_nested_attributes_for.inspect}" if ::RestfulJson::Options.debugging?
      
        super(attr_names)
      end

      def as_json_includes(*attr_names)
        self._as_json_includes = Array.wrap(attr_names)
      end
      alias_method :default_as_json_includes, :as_json_includes

      def as_json_excludes(*attr_names)
        self._as_json_excludes = Array.wrap(attr_names)
      end
    end

    # Instance methods

    # Works similar to as_json, but includes restful_json_nested symbols in :includes and adds an "id" key to the result with the value
    # of the primary key or array of keys. Also, if this instance has already been output in an ancestoral as_json, then no
    # associations are included.
    def as_json(options = {})
      puts "restful_json's as_json called on #{self.class} with options=#{options.inspect}. inspect=#{inspect}" if ::RestfulJson::Options.debugging?
      
      # unfollowed_object_ids attribute is to avoid circular references. it is an array of the object_ids whose children we should not output.
      # Rails already tries to handle this via setting the :encoder on the model's options, but I haven't spent the time to figure out why
      # it wasn't working for me in certain cases yet.
      was_already_as_jsoned = options[:unfollowed_object_ids].is_a?(Array) && options[:unfollowed_object_ids].include?(self.object_id)
      options[:unfollowed_object_ids] << self.object_id if options[:unfollowed_object_ids].is_a?(Array)

      includes = self._as_json_includes || []
      excludes = self._as_json_excludes || []
      if ::RestfulJson::Options.debugging?
        puts "as_json_includes=#{includes}"
        puts "as_json_excludes=#{excludes}"
      end

      accessible_attributes = (self.class.accessible_attributes.to_a || attributes.keys) - self.class.protected_attributes.to_a

      if was_already_as_jsoned || options[:restful_json_no_includes] || options[:restful_json_only] || !(options[:unfollowed_object_ids].is_a?(Array))
        if ::RestfulJson::Options.debugging?
          puts "called without options[:unfollowed_object_ids] so can't avoid circular references properly. if this happens to something as part of a restful_json controller request, there is a bug" if !(options[:unfollowed_object_ids].is_a?(Array))
          puts "avoiding circular reference by just outputting the already as_json'd instance without its associations as_json" if was_already_as_jsoned
          puts "having to ignore options[:restful_json_no_includes]" if options[:restful_json_no_includes]
          puts "restful_json_only=#{options[:restful_json_only]}" if options[:restful_json_only]
        end

        # return all accessible attributes
        result = {}
        
        includes_without_associations = includes.collect{|m|m.to_sym} - self.class.reflect_on_all_associations.collect{|a|a.name.to_sym}
        # add id to list of attributes we want, unless it is explicitly excluded
        attrs = ['id'] + accessible_attributes + includes_without_associations - excludes
        attrs = attrs - options[:except] if options.try(:key?, :except)
        attrs.delete('')
        attrs.collect{|m|m.to_sym}.uniq.each do |attr_name|
          begin
            result[attr_name] = send(attr_name) if !options[:restful_json_only] || options[:restful_json_only].collect{|v|v.to_sym}.include?(attr_name.to_sym)
          rescue => e
            # not sure why this is happening
            puts "problem including attribute/method '#{attr_name}': #{e.message} #{e.backtrace}"
          end
        end

        puts "returning accessible attributes #{result.inspect}" if ::RestfulJson::Options.debugging?
        result
      else
        # otherwise, it includes associations defined as as_json_includes

        # Add id to the default list of methods called
        includes_with_associations = includes
        if options.try(:key?, :methods)
          includes_with_associations = includes_with_associations + options[:methods]
        end
        
        # apply includes client-supplied filter, not allowing client to supply non-allowed methods
        if options[:restful_json_include] && options[:restful_json_include].is_a?(Array)
          includes_with_associations = includes_with_associations.collect{|incl| incl if options[:restful_json_include].collect{|v|v.to_sym}.include?(incl.to_sym)}.compact
        end
        
        # add id to list of attributes we want, unless it is explicitly excluded
        options[:methods] = ([:id] + includes_with_associations - excludes).collect{|m|m.to_sym}.uniq

        if options.try(:key?, :except)
          options[:except] = options[:except] + excludes
        else
          options[:except] = as_json_excludes if excludes && excludes.size > 0
        end

        restricted_attributes = attributes.keys - accessible_attributes
        if restricted_attributes && restricted_attributes.size > 0
          if options[:except]
            options[:except] = (options[:except] + restricted_attributes).collect{|m|m.to_sym}.uniq
          else
            options[:except] = restricted_attributes.collect{|m|m.to_sym}
          end
        end

        puts "calling as_json(#{options.inspect})" if ::RestfulJson::Options.debugging?
        super(options)
      end
    end
  end
end
