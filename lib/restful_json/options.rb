module RestfulJson
  class Options
    @@controller_options = {
      # controller options
      #-------------------
      arel_predication_split: '!',
      cors_access_control_headers: {'Access-Control-Allow-Origin' => '*',
                                     'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
                                     'Access-Control-Max-Age' => '1728000'},
      cors_enabled: false,
      cors_preflight_headers: {'Access-Control-Allow-Origin' => '*',
                                'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
                                'Access-Control-Allow-Headers' => 'X-Requested-With, X-Prototype-Version',
                                'Access-Control-Max-Age' => '1728000'},
      ignore_bad_json_attributes: true,
      intuit_post_or_put_method: true,
      # Generated from Arel::Predications.public_instance_methods.collect{|c|c.to_s}.sort. To lockdown a little, defining these specifically.
      # See: https://github.com/rails/arel/blob/master/lib/arel/predications.rb
      multiple_value_arel_predications: ['does_not_match_all', 'does_not_match_any', 'eq_all', 'eq_any', 'gt_all', 
                                          'gt_any', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt_all', 'lt_any', 
                                          'lteq_all', 'lteq_any', 'matches_all', 'matches_any', 'not_eq_all', 'not_eq_any', 
                                          'not_in', 'not_in_all', 'not_in_any'],
      scavenge_bad_associations: true,
      suffix_json_attributes: true,
      supported_arel_predications: ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                     'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                     'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                     'not_in', 'not_in_all', 'not_in_any'],
      supported_functions: ['count', 'include', 'no_includes', 'only', 'skip', 'take', 'uniq'],
      value_split: ',',
      wrapped_json: false,
    }

    @@model_options = {
    }

    @@general_options = {
      debug: false
    }

    def self.configure(hash)
      hash.keys.each do |key|
        if @@general_options.key?(key)
          @@general_options[key] = hash[key]
        elsif @@controller_options.key?(key)
          @@controller_options[key] = hash[key]
        elsif @@model_options.key?(key)
          @@model_options[key] = hash[key]
        else
          puts "Unrecognized RestfulJson option '#{key}'"
        end
      end
    end

    def self.all
      @@general_options.merge(@@controller_options).merge(@@model_options)
    end

    def self.controller
      @@controller_options
    end

    def self.general
      @@general_options
    end

    def self.model
      @@model_options
    end

    def self.debugging?
      @@general_options[:debug]
    end

    def self.output
      puts
      puts "RestfulJson::Options:"
      hash = all
      hash.keys.each do |k|
        puts "#{k}: #{hash[k].inspect}"
      end
      puts
    end
  end
end
