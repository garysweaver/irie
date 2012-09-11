module RestfulJson
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :model_class, instance_writer: false
      class_attribute :model_singular_name, instance_writer: false
      class_attribute :model_plural_name, instance_writer: false

      # for each of the keys in the default controller config, make an associated class_attribute and set it to the value of the OpenStruct
      options_hash = RestfulJson::Options.controller
      options_hash.keys.each do |key|
        class_attribute key, instance_writer: false
        self.send("#{key}=".to_sym, options_hash[key])
      end
    end

    module ClassMethods

      def acts_as_restful_json(options = {})
        include ActsAsRestfulJsonInstanceMethods # intentionally not just InstanceMethods as those would be automatically included via ActiveSupport::Concern
        #before_filter :sanity_check
        after_filter :after_request
      end

    end
    
    module ActsAsRestfulJsonInstanceMethods
      
      # as method so can be overriden
      def convert_request_param_value_for_filtering(attr_name, value)
        value && ['NULL','null','nil'].include?(value) ? nil : value
      end
      
      def collected_accepts_nested_attributes_for
        @model_class._collected_accepts_nested_attributes_for || []
      end

      def parse_request_json
        if RestfulJson::Options.debugging?
          puts "params=#{params.inspect}"
          puts "request.body.read=#{request.body.read}"
          puts "will look for #{@__restful_json_model_singular} key in incoming request params" if self.wrapped_json
        end
        
        request_body_value = request.body.read
        request_body_string = request_body_value ? "#{request_body_value}" : nil

        result = nil
        if self.wrapped_json
          result = params[@__restful_json_model_singular]
        elsif request_body_string && request_body_string.length >= 2
          result = JSON.parse(request_body_string)
        else
          result = params
        end

        puts "parsed_request_json=#{result}" if RestfulJson::Options.debugging?
        result
      end
      
      def single_response_json(value)
        if self.wrapped_json
          {@__restful_json_model_singular.to_sym => value}
        else
          value
        end
      end
      
      def plural_response_json(value)
        if self.wrapped_json
          {@__restful_json_model_plural.to_sym => value}
        else
          value
        end
      end
            
      def initialize
        @model_singular_name = self.model_singular_name || self.class.name.chomp('Controller').split('::').last.singularize
        @model_plural_name = self.model_plural_name || @model_singular_name.pluralize
        @model_class = self.model_class || @model_singular_name.constantize

        raise "#{self.class.name} assumes that #{@model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless @model_class.ancestors.include?(ActiveRecord::Base)

        puts "'#{self}' set @model_class=#{@model_class}, @model_singular_name=#{@model_singular_name}, @model_plural_name=#{@model_plural_name}" if RestfulJson::Options.debugging?
      end
      
      def allowed_activerecord_model_attribute_keys(clazz)
        (clazz.accessible_attributes.to_a || clazz.new.attributes.keys) - clazz.protected_attributes.to_a
      end
      
      # If this is a preflight OPTIONS request, then short-circuit the
      # request, return only the necessary headers and return an empty
      # text/plain. Modified from Tom Sheffler's example in 
      # http://www.tsheffler.com/blog/?p=428 to allow customization.
      def cors_preflight_check?
        if self.cors_enabled && request.method == :options
          puts "CORS preflight check" if RestfulJson::Options.debugging?
          headers.merge!(self.cors_preflight_headers)
          # CORS returns as text to the browser as a step before the json, so is intentionally text type and not json.
          render :text => '', :content_type => 'text/plain'
          return true
        end
        false
      end
      
      # For all responses in this controller, return the CORS access control headers.
      # Modified from Tom Sheffler's example in http://www.tsheffler.com/blog/?p=428
      # to allow customization.
      def after_request
        if self.cors_enabled
          headers.merge!(self.cors_access_control_headers)
        end
      end
      
      # may be overidden in controller to have controller-wide access control
      def allowed?
        true        
      end
      
      def json_options
        # ?only=name,status will send as_json({restful_json_only: ['name','status']}) which forces :only and no associations for a simpler view
        # in addition, we're only selecting these fields in the query in index_it
        options = {}
        options[:restful_json_include] = params[:include].split(self.value_split).collect{|s|s.to_sym} if params[:include] && self.supported_functions.include?('include')
        options[:restful_json_no_includes] = true if params[:no_includes] && self.supported_functions.include?('no_includes')
        options[:restful_json_only] = params[:only].split(value_split).collect{|s|s.to_sym} if params[:only] && self.supported_functions.include?('only')
        # this is to track object_ids that have been output already. unless this is specified, just the model instance will be output.
        options[:unfollowed_object_ids] = []
        options
      end
      
      # may be overidden in controller to have method-specific access control
      def index_allowed?
        allowed?
      end
      
      def index
        puts "In #{self.class.name}.index" if RestfulJson::Options.debugging?
        @errors = nil
        
        unless index_allowed?
          puts "user not allowed to call index on #{self.class.name}" if RestfulJson::Options.debugging?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end
        
        return if cors_preflight_check?
        
        before_index_it
        index_it unless @errors
        after_index_it unless @errors

        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_plural}".to_sym, @value)
        respond_to do |format|
          if @errors
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @errors, status: (@error_type || :internal_server_error) }
          else
            format.json { render json: plural_response_json(@value.try(:as_json, json_options)) }
          end
        end
      end

      # anything that needs to happen before the resource index (list) is retrieved
      def before_index_it
      end
      
      # retrieve the resource index (list)
      def index_it
        begin
          # TODO: continue to explore filtering, etc. and look into extension of this project to use Sunspot/SOLR.
          # TODO: Darrel Miller/Ted M. Young suggest reviewing these: http://stackoverflow.com/a/4028874/178651
          #       http://www.ietf.org/rfc/rfc3986.txt  http://tools.ietf.org/html/rfc6570
          # TODO: Easier paging. Eugen Paraschiv (a.k.a. baeldung) has a good post here, even though is in context of Spring:
          #       http://www.baeldung.com/2012/01/18/rest-pagination-in-spring/
          #       http://www.iana.org/assignments/link-relations/link-relations.
          #       More on Link header: http://blog.steveklabnik.com/posts/2011-08-07-some-people-understand-rest-and-http
          #       example of Link header:
          #       Link: </path/to/resource?other_params_go_here&page=2>; rel="next", </path/to/resource?other_params_go_here&page=9999>; rel="last"
          #       will_paginate looks like it might be a good match
          
          # Using scoped and separate wheres if params present similar to solution provided by
          # John Gibb in http://stackoverflow.com/a/5820947/178651
          t = @model_class.arel_table
          value = @model_class.scoped
          # if "only" request param specified, only return those fields- this is important for uniq to be useful
          if params[:only] && self.supported_functions.include?('only')
            value.select(params[:only].split(self.value_split).collect{|s|s.to_sym})
          end
          
          # handle foo=bar, foo^eq=bar, foo^gt=bar, foo^gteq=bar, etc.
          allowed_activerecord_model_attribute_keys(@model_class).each do |attribute_key|
            puts "Finding #{@model_class}" if RestfulJson::Options.debugging?
            param = params[attribute_key]
            if self.supported_arel_predications.include?('eq')
              value = value.where(attribute_key => convert_request_param_value_for_filtering(attribute_key, param)) if param.present?
            end
            # supported AREL predications are suffix of ^ and predication in the parameter name
            self.supported_arel_predications.each do |arel_predication|
              param = params["#{attribute_key}#{self.arel_predication_split}#{arel_predication}"]
              if param.present?
                one_or_more_param = self.multiple_value_arel_predications.include?(arel_predication) ? param.split(value_split).collect{|v|convert_request_param_value_for_filtering(attribute_key, v)} : convert_request_param_value_for_filtering(attribute_key, param)
                puts ".where(value[#{attribute_key.to_sym.inspect}].call(#{arel_predication.to_sym.inspect}, '#{one_or_more_param}'))" if RestfulJson::Options.debugging?
                value = value.where(t[attribute_key.to_sym].try(arel_predication.to_sym, one_or_more_param))
              end
            end
          end
          
          # AREL equivalent of SQL OFFSET
          if params[:skip] && self.supported_functions.include?('skip')
            value = value.take(params[:skip])
          end
          
          # AREL equivalent of SQL LIMIT
          if params[:take] && self.supported_functions.include?('take')
            value = value.take(params[:take])
          end
          
          # ?uniq= will return unique records
          if params[:uniq] && self.supported_functions.include?('uniq')
            value = value.uniq
          end

          # ?count= will return a count
          if params[:count] && self.supported_functions.include?('count')
            value = value.count
          end
          # Sorts can either be specified by sortby=color&sortby=shape or comma-delimited like sortby=color,shape, or some combination.
          # The order in the url is the opposite of the order applied, so first sort param is dominant.
          # Sort direction can be specified across all sorts in the request by sort=asc or sort=desc, or the sort can be specified by
          # + or - at the beginning of the sortby, like sortby=+color,-shape to specify ascending sort on color and descending sort on
          # shape.
          #sortby=params[:sortby] && self.supported_functions.include?('sortby')
          #if sortby
          #  expanded_sortby_array=[]
          #  sortby.each do |sortparam|
          #    # assuming that since params passed in url that spaces are not being added in comma-delimited sorts
          #    expanded_sortby_array << sortparam.split(',')
          #    # TODO: in progress of adding, sorry...
          #  end
          #end
          
          # could just return value, but trying to be consistent with create/update that need to return flag of success
          @value = value
        rescue => e
          @errors = {errors: [e]}
        end
      end

      # anything that needs to happen after the resource index (list) is retrieved
      def after_index_it
      end
      
      # may be overidden in controller to have method-specific access control
      def show_allowed?
        allowed?
      end

      def show
        puts "In #{self.class.name}.show" if RestfulJson::Options.debugging?
        @errors = nil
        
        unless show_allowed?
          puts "user not allowed to call show on #{self.class.name}" if RestfulJson::Options.debugging?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end
        
        return if cors_preflight_check?

        before_show_it
        show_it unless @errors
        after_show_it unless @errors
        
        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)
        
        respond_to do |format|
          if @errors
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @errors, status: (@error_type || :internal_server_error) }
          else
            format.json { render json: single_response_json(@value.try(:as_json, json_options)) }
          end
        end
      end

      # anything that needs to happen before the resource is retrieved for showing
      def before_show_it
      end
      
      # retrieve the resource for showing
      def show_it
        begin
          puts "Attempting to show #{@model_class.try(:name)} with id #{params[:id]}" if RestfulJson::Options.debugging?
          # could just return value, but trying to be consistent with create/update that need to return flag of success
          @value = @model_class.find(params[:id])
        rescue => e
          @errors = {errors: [e]}
        end
      end

      # anything that needs to happen after the resource is retrieved for showing
      def after_show_it
      end
      
      # may be overidden in controller to have method-specific access control
      def create_allowed?
        allowed?
      end
      
      # POST /#{model_plural}.json
      def create
        puts "In #{self.class.name}.create" if RestfulJson::Options.debugging?
        @errors = nil

        @request_json = parse_request_json
        
        if self.intuit_post_or_put_method
          if @request_json && @request_json[:id]
            # We'll assume this is an update because the id was sent in- make it look like it came in via PUT with id param
            puts "THIS CAME INTO create BUT SINCE @request_json[:id] RETURNED A VALUE, WE WILL SET params[:id] = #{@request_json[:id]} AND CALL update INSTEAD, SINCE self.intuit_post_or_put_method" if RestfulJson::Options.debugging?
            params[:id] = @request_json[:id]
            return update
          else
            puts "ASSUMING THIS IS REALLY A create SINCE @request_json was nil or had no :id key: @request_json=#{@request_json}" if RestfulJson::Options.debugging?
          end
        end
        
        unless create_allowed?
          puts "user not allowed to call create on #{self.class.name}" if RestfulJson::Options.debugging?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end
        
        return if cors_preflight_check?
        
        before_create_or_update_it
        before_create_it unless @errors
        success = create_it unless @errors
        after_create_it unless @errors || !success
        after_create_or_update_it unless @errors || !success

        if RestfulJson::Options.debugging?
          puts "Failed update_it with errors #{(@value.try(:errors)).inspect}" unless success
        end

        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)
        
        respond_to do |format|
          if @errors
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @errors, status: (@error_type || :internal_server_error) }
          elsif success
            # note: status is magic- automatically sets HTTP code to 201 since status is created
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: single_response_json(@value.try(:as_json, json_options)), status: :created, location: @value.as_json(json_options) }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @value.errors, status: :unprocessable_entity }
          end
        end
      end

      # anything that needs to happen before the resource is created or updated. this happens before before_create_it/before_update_it.
      def before_create_or_update_it
      end

      # anything that needs to happen after the resource is created or updated. this happens after after_create_it/after_update_it.
      def after_create_or_update_it
      end

      # anything that needs to happen before the resource is created
      def before_create_it
      end
      
      # create the specified resource
      def create_it
        begin
          puts "create_it: @model_class=#{@model_class} @request_json=#{@request_json}" if RestfulJson::Options.debugging?
          parsed_and_converted_json = convert_parsed_json(@model_class, @request_json)
          puts "#{@model_class.name}.new(#{parsed_and_converted_json.inspect})" if RestfulJson::Options.debugging?
          @value = @model_class.new(parsed_and_converted_json)
          puts "Attempting #{@model_class.name}.save" if RestfulJson::Options.debugging?
          @value.save
        rescue => e
          @errors = {errors: [e]}
        end
      end

      # anything that needs to happen after the resource is created
      def after_create_it
      end
      
      # may be overidden in controller to have method-specific access control
      def update_allowed?
        allowed?
      end
      
      # PUT /#{model_plural}/1.json
      def update
        puts "In #{self.class.name}.update" if RestfulJson::Options.debugging?
        @errors = nil

        @request_json = parse_request_json unless @request_json # may be set in create method already
        
        unless update_allowed?
          puts "user not allowed to call update on #{self.class.name}" if RestfulJson::Options.debugging?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end
        
        return if cors_preflight_check?
        
        before_create_or_update_it
        before_update_it unless @errors
        success = update_it unless @errors
        after_update_it unless @errors || !success
        after_create_or_update_it unless @errors || !success

        if RestfulJson::Options.debugging?
          puts "Failed update_it with errors #{(@value.try(:errors)).inspect}" unless success
        end
        
        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)
        
        respond_to do |format|
          if @errors
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @errors, status: (@error_type || :internal_server_error) }
          elsif success
            # note: status is magic- automatically sets HTTP code to 200 since status is ok
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: single_response_json(@value.try(:as_json, json_options)), status: :ok }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @value.try(:errors), status: :unprocessable_entity }
          end
        end
      end

      # anything that needs to happen before the resource is updated
      def before_update_it
      end
      
      # update the specified resource
      def update_it
        begin
          if RestfulJson::Options.debugging?
            puts "update_it: @model_class=#{@model_class} @request_json=#{@request_json}"
            puts "@model_class.find(#{params[:id]})"
          end
          @value = @model_class.find(params[:id])        
          parsed_and_converted_json = convert_parsed_json(@model_class, @request_json)        
          puts "Attempting #{@value}.update_attributes(#{parsed_and_converted_json.inspect})" if RestfulJson::Options.debugging?
          success = @value.update_attributes(parsed_and_converted_json)
          success
        rescue => e
          @errors = {errors: [e]}
        end
      end

      # anything that needs to happen after the resource is updated
      def after_update_it
      end
      
      # may be overidden in controller to have method-specific access control
      def destroy_allowed?
        allowed?
      end
      
      # DELETE /#{model_plural}/1.json
      def destroy
        puts "In #{self.class.name}.destroy" if RestfulJson::Options.debugging?
        @errors = nil
        
        unless destroy_allowed?
          puts "user not allowed to call destroy on #{self.class.name}" if RestfulJson::Options.debugging?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end
        
        return if cors_preflight_check?
        
        before_destroy_it
        success = destroy_it unless @errors
        after_destroy_it unless @errors || !success

        if RestfulJson::Options.debugging?
          puts "Failed destroy_it but returning ok anyway, as it might have been deleted between the time we checked for it and when we tried to delete it" unless success
        end

        respond_to do |format|
          if @errors
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @errors, status: (@error_type || :internal_server_error) }
          else
            # note: status is magic- automatically sets HTTP code to 200 since status is ok
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :ok }
          end
        end
      end

      # anything that needs to happen before the resource is destroyed
      def before_destroy_it
      end
      
      # destroy the specified resource
      def destroy_it
        begin
          puts "Attempting to destroy #{@model_class.try(:name)} with id #{params[:id]}" if RestfulJson::Options.debugging?
          @model_class.where(id: params[:id]).first ? @model_class.destroy(params[:id]) : true
        rescue => e
          @errors = {errors: [e]}
        end
      end

      # anything that needs to happen after the resource is destroyed
      def after_destroy_it
      end
      
      # Because most of the time having to specify (name)_attributes as the name of a key in the incoming json is a pain,
      # we'll change each key (name) to (name)_attributes if it is a name. Recurses the provided json, outputting a
      # a hash with the key names "fixed".
      #
      # Also unless an incoming json object for an association belongs to collected_accepts_nested_attributes_for in
      # the model class then we'll assume that either the client either meant to add/update/remove associated id(s) or
      # the client didn't mean to do anything with the association.
      #
      # Finally we'll just ignore all attributes that the client may not have meant to send in, with the exception of
      # id which will assume the client wanted to update.
      def convert_parsed_json(clazz, value)
        puts "In convert_parsed_json(#{clazz}, #{value})" if RestfulJson::Options.debugging?

        unless value
          return nil
        end

        if self.scavenge_bad_associations || self.ignore_bad_json_attributes || self.suffix_json_attributes

          start = Time.now

          puts "Prior to conversion(s): #{value}" if RestfulJson::Options.debugging?
          
          # Create a reference hash of association names to their classes
          association_name_sym_to_association = {}
          clazz.reflect_on_all_associations.each do |association|
            association_name_sym_to_association[association.name] = association
          end
          accessible_attributes = allowed_activerecord_model_attribute_keys(clazz)
          
          # If you send in an association as a full json object and didn't define it as accepts_nested_attributes_for
          # then you probably either didn't mean to send it or you meant to set this model's foreign id with its id. 
          # Is this the right assumption? We could make it explicit at some point or make this a configuration option.
          if self.scavenge_bad_associations
            fkeys_scavenged = []
            if value.is_a?(Hash)
              value.keys.each do |key|
                key_sym = key.to_sym
                key_sym_without_suffix = (key.end_with?('_attributes') ? key.chomp('_attributes') : key).to_sym
                if association_name_sym_to_association.keys.include?(key_sym_without_suffix) && !collected_accepts_nested_attributes_for.include?(key_sym_without_suffix)
                  puts "JSON for #{key_sym} can't be persisted because #{clazz}'s accepts_nested_attributes_for didn't include it, but we're going to scavenge it for an id" if RestfulJson::Options.debugging?
                  # scavenge json that isn't accepts_nested_attributes_for for an id
                  association = association_name_sym_to_association[key_sym_without_suffix]
                  foreign_key = association.options[:foreign_key] || association.try(:foreign_key)
                  if association.macro == :belongs_to
                    foreign_key ||= "#{association.name}_id"
                  elsif association.macro == :has_and_belongs_to_many
                    foreign_key ||= "#{association.name.singularize}_id"
                  end
                  
                  # if this foreign id is settable and it wasn't explicitly set to a non-null value, update it
                  if accessible_attributes.include?(foreign_key.to_s)
                    association_hash = value[key_sym]
                    if association_hash.nil? || association_hash.is_a?(Hash)
                      new_value = association_hash ? association_hash[:id] : nil
                      # if passes in a hash, only set it if :id is specified, or if passing in nil instead of hash. can't support passing in :id in hash as nil,
                      # because that would imply a create, and can't create unless accepts_nested_attributes_for
                      if (association_hash && association_hash.key?(:id) && new_value) || association_hash.nil?
                        if value[foreign_key.to_sym]
                          if RestfulJson::Options.debugging?
                            puts "Didn't set foreign key #{foreign_key.to_sym} on #{clazz} to #{new_value} because it was already set to #{value[foreign_key.to_sym]}" if "#{new_value}" != "#{value[foreign_key.to_sym]}"
                          end
                        else
                          comment = association_hash ? " (value from id in JSON hash sent as #{key_sym})" : ''
                          puts "Set foreign key #{foreign_key.to_sym} on #{clazz} to #{new_value}#{comment}" if RestfulJson::Options.debugging?
                          value[foreign_key.to_sym] = new_value
                          fkeys_scavenged << "#{foreign_key}=#{new_value}#{comment}"
                        end
                      else
                        puts "Didn't set foreign key #{foreign_key.to_sym} on #{clazz} because there was no id in JSON in passed in #{key_sym}, and #{key_sym} was not set to nil." if RestfulJson::Options.debugging?
                      end
                    else
                      puts "Didn't set foreign key #{foreign_key.to_sym} on #{clazz} because #{key_sym} was not of nil or Hash type." if RestfulJson::Options.debugging?
                    end
                  else
                    puts "Couldn't set #{foreign_key.to_sym.inspect} on #{clazz} with the id from association JSON because it wasn't in the list of allowed attributes to mass assign: #{accessible_attributes.join(', ')}. To intuit ids from association JSON from it, add attr_accessible #{foreign_key.to_sym.inspect} to #{clazz}. To avoid this warning, either set self.scavenge_bad_associations to false, or stop sending association json for #{key.to_sym}." if RestfulJson::Options.debugging?
                  end
                end
              end
            end
            
            if RestfulJson::Options.debugging?
              puts "For #{clazz}'s JSON, set the following (foreign) keys: #{fkeys_scavenged.join(',')} where those keys were for belongs_to or habtm assoc's that weren't already set and had associated JSON data with id attributes" if fkeys_scavenged.size > 0
            end
          end

          if RestfulJson::Options.debugging?
            puts "After self.scavenge_bad_associations: #{value}" if self.scavenge_bad_associations
          end
          
          # Ignore the attributes that are misspelled or otherwise not accessible, because in the emitted json, things
          # may have been included that just can't be updated.
          if self.ignore_bad_json_attributes
            if RestfulJson::Options.debugging?
              puts "#{clazz} accepts_nested_attributes_for: #{collected_accepts_nested_attributes_for.join(',')}"
              puts "#{clazz} accessible_attributes: #{accessible_attributes.join(',')}"
            end
            removed_attributes = []
            if value.is_a?(Hash)
              value.keys.each do |key|
                key_sym_without_suffix = (key.end_with?('_attributes') ? key.chomp('_attributes') : key).to_sym
                if !collected_accepts_nested_attributes_for.include?(key_sym_without_suffix) && !accessible_attributes.include?(key)
                  value.delete(key)
                  removed_attributes << key
                end
              end
            end
            if RestfulJson::Options.debugging?
              puts "For #{clazz}'s JSON, removed keys: #{removed_attributes.join(',')} that weren't in accepts_nested_attributes_for or accessible_attributes" if removed_attributes.size > 0
            end
          end

          if RestfulJson::Options.debugging?
            puts "After self.ignore_bad_json_attributes: #{value}" if self.ignore_bad_json_attributes
          end
          
          # Append _attributes to associations that haven't gotten the axe yet, and expand those associations.
          if self.suffix_json_attributes
            suffixed_attributes = []
            if value.is_a?(Array)
              value = value.collect{|v|convert_parsed_json(clazz, v)}
            elsif value.is_a?(Hash)
              converted_value = {}
              value.keys.each do |key|
                if association_name_sym_to_association.keys.include?(key.to_sym)
                  converted_value["#{key}_attributes".to_sym] = convert_parsed_json(association_name_sym_to_association[key.to_sym].class_name.constantize, value[key])
                  suffixed_attributes << key
                else
                  converted_value[key] = value[key]
                end
              end
              value = converted_value
            end
            
            if RestfulJson::Options.debugging?
              puts "For #{clazz}'s JSON, suffixed keys: #{suffixed_attributes.join(',')} that has Hash values and keys that were listed in this classes association names: #{association_name_sym_to_association.keys}" if suffixed_attributes.size > 0
            end
          end

          if RestfulJson::Options.debugging?
            puts "After self.suffix_json_attributes: #{value}" if self.suffix_json_attributes
            puts "Time to do requested conversions: #{Time.now - start} sec"
            puts "Converted request json: #{value}" if RestfulJson::Options.debugging?
          end
        end
        
        value
      end
    end
  end
end
