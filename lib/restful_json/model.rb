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
      # works just like normal as_json, but includes restful_json_nested symbols in :includes
      def as_json(options = nil)
        puts "restful_json's as_json called with options=#{options.inspect}"
        puts "self.class.as_json_includes_array()=#{self.class.as_json_includes_array()}"
        new_options = options ? options.dup : {}
        as_json_includes = []
        as_json_includes = as_json_includes + self.class.as_json_includes_array()
        if options.try(:key?, :methods)
          as_json_includes = as_json_includes + options[:methods]
        end
        new_options[:methods] = as_json_includes
        super(new_options)
      end
    end
  end
end
