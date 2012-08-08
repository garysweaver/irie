module RestfulJson
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :_as_json_includes, instance_writer: false
      class_attribute :_as_json_excludes, instance_writer: false
    end

    module ClassMethods

      # works just like accepts_nested_attributes_for, except it stores any symbols passed in attr_names as in as_json :includes
      #def accepts_nested_attributes_for(*attr_names)
      #  puts "restful_json's accepts_nested_attributes_for called with attr_names=#{attr_names.inspect}"
      #  puts "#{self.class.name}.reflect_on_all_associations=#{self.reflect_on_all_associations.inspect}"
      #  
      #  unless attr_names.nil?
      #    if attr_names.is_a?(Array)
      #      attr_names.each do |attr_name|
      #        @@__as_json_includes << attr_name if attr_name.is_a?(Symbol)
      #      end
      #    elsif attr_names.is_a?(Symbol)
      #      @@__as_json_includes << attr_name
      #    end
      #  end
      #
      #  super(attr_names)
      #end

      def as_json_includes (*attr_names)
        self._as_json_includes = Array.wrap(attr_names)
      end
      alias_method :default_as_json_includes, :as_json_includes

      def as_json_excludes (*attr_names)
        self._as_json_excludes = Array.wrap(attr_names)
      end
    end

    # Instance methods

    # Works similar to as_json, but includes restful_json_nested symbols in :includes and adds an "id" key to the result with the value
    # of the primary key or array of keys. Also, if this instance has already been output in an ancestoral as_json, then no
    # associations are included.
    def as_json(options = {})
      puts "restful_json's as_json called with options=#{options.inspect}"
      
      unless options[:restful_json_ancestors].is_a?(Array)
        puts "as_json not called with an array in options[:restful_json_ancestors] so taking a wild guess and just calling super(#{options})"
        return super(options)
      end
      was_already_as_jsoned = options[:restful_json_ancestors].include?(self.object_id)
      options[:restful_json_ancestors] << self.object_id

      includes = self._as_json_includes || []
      excludes = self._as_json_excludes || []
      puts "as_json_includes=#{includes}"
      puts "as_json_excludes=#{excludes}"

      if was_already_as_jsoned || options[:restful_json_no_includes] || options[:restful_json_only]
        puts "avoiding circular reference by just outputting the already as_json'd instance without its associations as_json" if was_already_as_jsoned
        puts "ignoring as_json_includes" if options[:restful_json_no_includes]
        puts "restful_json_only=#{options[:restful_json_only]}" if options[:restful_json_only]

        # return all accessible attributes
        result = {}
        # solution to get keys from: http://stackoverflow.com/a/1526328/178651
        accessible_attributes = self.class.new.attributes.keys - self.class.protected_attributes.to_a
        includes_without_associations = includes.collect{|m|m.to_sym} - self.class.reflect_on_all_associations.collect{|a|a.name.to_sym}
        # add id to list of attributes we want, unless it is explicitly excluded
        attrs = ['id'] + accessible_attributes + includes_without_associations - excludes
        attrs = attrs - options[:except] if options.try(:key?, :except)
        attrs.collect{|m|m.to_sym}.uniq.each do |attr_name|
          result[attr_name] = send(attr_name) if !options[:restful_json_only] || options[:restful_json_only].collect{|v|v.to_sym}.include?(attr_name.to_sym)
        end

        puts "returning accessible attributes #{result.inspect}"
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

        puts "calling as_json(#{options.inspect})"
        super(options)
      end
    end
  end
end
