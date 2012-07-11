module RestfulJson
  module Model
    @@__to_json_options = {}

    def set_default_json_format
      @@__to_json_options[:default] = options
    end

    def set_json_format(name, options)
      puts "set_json_format cannot be called with nil format name. instead use set_default_json_format. debug: options=#{options}" if name.nil?
      @@__to_json_options[name.to_sym] = options
    end

    def get_json_format(name = :default)
      @@__to_json_options[name.to_sym]
    end
  end
end
