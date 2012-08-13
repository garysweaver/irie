module RestfulJson
  class Options
    @@data = {
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
        scavenge_bad_associations_for_id_only: true,
        suffix_json_attributes: true,
        supported_arel_predications: ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                       'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                       'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                       'not_in', 'not_in_all', 'not_in_any'],
        value_split: ',',
        wrapped_json: false
      }

    def self.configure(hash)
      @@data.merge!(hash)
    end

    # calling it to_hash just in case we change the implementation to Struct/OpenStruct/etc.
    def self.to_hash
      @@data
    end

    def self.output
      puts
      puts "RestfulJson::Options:"
      @@data.keys.each do |k|
        puts "#{k}: #{@@data[k].inspect}"
      end
      puts
    end
  end
end
