module RestfulJson
  module Model
    @@__as_json_includes_and_accepts_nested_attributes_for=[]

    # works just like accepts_nested_attributes_for, except it stores any symbols passed in attr_names as in as_json :includes
    #def accepts_nested_attributes_for(*attr_names)
    #  puts "restful_json's accepts_nested_attributes_for called with attr_names=#{attr_names.inspect}"
    #  puts "#{self.class.name}.reflect_on_all_associations=#{self.reflect_on_all_associations.inspect}"
    #  
    #  unless attr_names.nil?
    #    if attr_names.is_a?(Array)
    #      attr_names.each do |attr_name|
    #        @@__as_json_includes_and_accepts_nested_attributes_for << attr_name if attr_name.is_a?(Symbol)
    #      end
    #    elsif attr_names.is_a?(Symbol)
    #      @@__as_json_includes_and_accepts_nested_attributes_for << attr_name
    #    end
    #  end
    #
    #  super(attr_names)
    #end

    def default_as_json_includes(*attr_names)
      unless attr_names.nil?
        if attr_names.is_a?(Array)
          attr_names.each do |attr_name|
            @@__as_json_includes_and_accepts_nested_attributes_for << attr_name if attr_name.is_a?(Symbol)
          end
        else
          @@__as_json_includes_and_accepts_nested_attributes_for << attr_name
        end
      end
    end

    def as_json_includes_array
      @@__as_json_includes_and_accepts_nested_attributes_for
    end

    module InstanceMethods
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

        if options[:restful_json_only]
          puts "restful_json_only=#{options[:restful_json_only]}"
          # if specifies :restful_json_only via controller, it includes only what is specified as an :only and does not include associations
          result = {}
          options[:restful_json_only].each do |attr_name|
            result[attr_name] = send(attr_name)
          end
          puts "returning #{result.inspect}"
          add_id_if_needed(self.class, result)
        elsif was_already_as_jsoned
          puts "avoiding circular reference by just outputting the already as_json'd instance without its associations as_json"
          # return all accessible attributes
          result = {}
          # solution to get keys from: http://stackoverflow.com/a/1526328/178651
          accessible_attributes = self.class.new.attributes.keys - self.class.protected_attributes.to_a
          accessible_attributes.each do |attr_name|
            result[attr_name] = send(attr_name)
          end
          puts "returning accessible attributes #{result.inspect}"
          add_id_if_needed(self.class, result)
        else
          # otherwise, it includes associations defined as default_as_json_includes
          puts "self.class.as_json_includes_array()=#{self.class.as_json_includes_array()}"
          as_json_includes = []
          as_json_includes = as_json_includes + self.class.as_json_includes_array()
          if options.try(:key?, :methods)
            as_json_includes = as_json_includes + options[:methods]
          end
          options[:methods] = as_json_includes
          puts "calling as_json(#{options.inspect})"
          add_id_if_needed(self.class, super(options))
        end
      end

    protected
      def add_id_if_needed(clazz, value)
        puts "In add_id_if_needed(#{clazz}, #{value})"
        
        if value.is_a?(Array)
          return value.collect{|v|add_id_if_needed(clazz, v)}
        elsif value.is_a?(Hash)
          result = {}
          unless value['id']
            if clazz.primary_key.is_a?(String)
              value['id'] = value[clazz.primary_key]
            elsif clazz.primary_key.is_a?(Array)
              # composite_primary_keys gem returns primary_key as an array of symbols, but values in json hash are strings, so we'll get the key values as
              # an array, convert them to strings, and look them up to provide an array of the key values. It's the best we can do.
              value['id'] = clazz.primary_key.collect{|pk|value[pk.to_s]}
            end
          end

          association_name_sym_to_class = {}
          clazz.reflect_on_all_associations.each do |association|
            association_name_sym_to_class[association.name] = association.class_name.constantize
          end
          value.keys.each do |key|
            # assuming that associations are not suffixed with _attributes
            if association_name_sym_to_class.keys.include?(key.to_sym)
              result[key] = add_id_if_needed(association_name_sym_to_class[key.to_sym], value[key])
            else
              result[key] = value[key]
            end
          end
          return result
        else
          return value
        end
      end
    end
  end
end
