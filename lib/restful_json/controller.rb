module RestfulJson
  module Controller
    extend ActiveSupport::Concern
    include TwinTurbo::Controller

    included do
      class_attribute :model_class, instance_writer: false

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
        before_filter :before_request
        after_filter :after_request
      end

    end
    
    module ActsAsRestfulJsonInstanceMethods

      # convenience-actionpack override for CanCan access error to use forbidden status
      alias_method :on_action_error_restful_json_renamed :on_action_error
      def on_action_error(error)
        if error.is_a?(CanCan::AccessDenied)
          respond_with({errors: [error.message]}, location: nil, status: :forbidden)
        else
          on_action_error_restful_json_renamed(error)
        end
      end
      
      # as method so can be overriden
      def convert_request_param_value_for_filtering(attr_name, value)
        value && ['NULL','null','nil'].include?(value) ? nil : value
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
        @model_class = self.model_class || self.class.name.chomp('Controller').split('::').last.singularize.constantize

        raise "#{self.class.name} assumes that #{@model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless @model_class.ancestors.include?(ActiveRecord::Base)

        puts "'#{self}' set @model_class=#{@model_class}" if RestfulJson::Options.debugging?
      end
      
      def allowed_activerecord_model_attribute_keys(clazz)
        (clazz.accessible_attributes.to_a || clazz.new.attributes.keys) - clazz.protected_attributes.to_a
      end
      
      # Initializes @value and @errors to nil, and if this is a preflight OPTIONS request, then it will short-circuit the
      # request, return only the necessary headers and return an empty text/plain. Modified from Tom Sheffler's example in 
      # http://www.tsheffler.com/blog/?p=428
      def before_request
        # initialize vars
        @value = nil
        @errors = nil

        if self.cors_enabled && request.method == :options
          puts "CORS preflight check" if RestfulJson::Options.debugging?
          headers.merge!(self.cors_preflight_headers)
          # CORS returns as text to the browser as a step before the json, so is intentionally text type and not json.
          render :text => '', :content_type => 'text/plain'
          # returning false to indicate that we should not proceed after this before_filter method
          return false
        end
        # returning true to indicate that we should proceed after this before_filter method
        true
      end
      
      # For all responses in this controller, return the CORS access control headers.
      # Modified from Tom Sheffler's example in http://www.tsheffler.com/blog/?p=428
      # to allow customization.
      def after_request
        if self.cors_enabled
          headers.merge!(self.cors_access_control_headers)
        end
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
      
      def index
        wrap do
          puts "In #{self.class.name}.index" if RestfulJson::Options.debugging?
          
          before_index_it
          index_it unless @errors
          after_index_it unless @errors

          respond_with (@errors ? @errors || @value)
        end
      end

      # anything that needs to happen before the resource index (list) is retrieved
      def before_index_it
      end
      
      # retrieve the resource index (list)
      def index_it
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
            if param.present?
              puts "value.where(#{attribute_key.inspect} => convert_request_param_value_for_filtering(#{attribute_key.inspect}, #{param.inspect}))" if RestfulJson::Options.debugging?
              value = value.where(attribute_key => convert_request_param_value_for_filtering(attribute_key, param))
            end
          end
          # supported AREL predications are suffix of ^ and predication in the parameter name
          self.supported_arel_predications.each do |arel_predication|
            param = params["#{attribute_key}#{self.arel_predication_split}#{arel_predication}"]
            if param.present?
              one_or_more_param = self.multiple_value_arel_predications.include?(arel_predication) ? param.split(value_split).collect{|v|convert_request_param_value_for_filtering(attribute_key, v)} : convert_request_param_value_for_filtering(attribute_key, param)
              puts ".where(t[#{attribute_key.to_sym.inspect}].try(#{arel_predication.to_sym.inspect}, #{one_or_more_param.inspect}))" if RestfulJson::Options.debugging?
              value = value.where(t[attribute_key.to_sym].try(arel_predication.to_sym, one_or_more_param))
            end
          end
        end
        
        # AREL equivalent of SQL OFFSET
        value = value.take(params[:skip]) if params[:skip] && self.supported_functions.include?('skip')
        
        # AREL equivalent of SQL LIMIT
        value = value.take(params[:take]) if params[:take] && self.supported_functions.include?('take')
        
        # ?uniq= will return unique records
        value = value.uniq if params[:uniq] && self.supported_functions.include?('uniq')

        # ?count= will return a count
        value = value.count if params[:count] && self.supported_functions.include?('count')

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
      end

      # anything that needs to happen after the resource index (list) is retrieved
      def after_index_it
      end
      
      def show
        wrap do
          puts "In #{self.class.name}.show" if RestfulJson::Options.debugging?

          before_show_it
          show_it unless @errors
          after_show_it unless @errors
          
          puts "Failed show with errors=#{@errors.inspect}" if @errors && RestfulJson::Options.debugging?
          
          respond_with (@errors ? @errors || @value)
        end
      end

      # anything that needs to happen before the resource is retrieved for showing
      def before_show_it; end
      
      # retrieve the resource for showing
      def show_it
        puts "Attempting to show #{@model_class.try(:name)} with id #{params[:id]}" if RestfulJson::Options.debugging?
        # could just return value, but trying to be consistent with create/update that need to return flag of success
        @value = @model_class.find(params[:id])
      end

      # anything that needs to happen after the resource is retrieved for showing
      def after_show_it; end
      
      # POST /#{model_plural}.json
      def create
        wrap do
          puts "In #{self.class.name}.create" if RestfulJson::Options.debugging?

          @request_json = parse_request_json
          
          if self.intuit_post_or_put_method && @request_json && @request_json[:id]
            # We'll assume this is an update because the id was sent in- make it look like it came in via PUT with id param
            puts "This was an update request disguised as a create request" if RestfulJson::Options.debugging?
            params[:id] = @request_json[:id]
            return update
          end
          
          before_create_or_update_it
          before_create_it unless @errors
          success = create_it unless @errors
          after_create_it unless @errors || !success
          after_create_or_update_it unless @errors || !success

          puts "Failed create with errors=#{@errors.inspect}" if (@errors || !success) && RestfulJson::Options.debugging?
          respond_with (@errors ? @errors || @value)
        end
      end

      # anything that needs to happen before the resource is created or updated. this happens before before_create_it/before_update_it.
      def before_create_or_update_it
        authorize! :create, @model_class
      end

      # anything that needs to happen after the resource is created or updated. this happens after after_create_it/after_update_it.
      def after_create_or_update_it; end

      # anything that needs to happen before the resource is created
      def before_create_it; end
      
      # create the specified resource
      def create_it
        @value = @model_class.new(permitted_params)
        @value.save
      end

      # anything that needs to happen after the resource is created
      def after_create_it; end
      
      # PUT /#{model_plural}/1.json
      def update
        wrap do
          puts "In #{self.class.name}.update" if RestfulJson::Options.debugging?

          @request_json = parse_request_json unless @request_json # may be set in create method already
          
          before_create_or_update_it
          before_update_it unless @errors
          success = update_it unless @errors
          after_update_it unless @errors || !success
          after_create_or_update_it unless @errors || !success

          puts "Failed update with errors=#{@errors.inspect}" if (@errors || !success) && RestfulJson::Options.debugging?
          respond_with (@errors ? @errors || @value)
        end
      end

      # anything that needs to happen before the resource is updated
      def before_update_it
      end
      
      # update the specified resource
      def update_it
        @value = @model_class.find(params[:id})
        @value.update_attributes(permitted_params)
        @value.save
      end

      # anything that needs to happen after the resource is updated
      def after_update_it; end
      
      # DELETE /#{model_plural}/1.json
      def destroy
        wrap do
          puts "In #{self.class.name}.destroy" if RestfulJson::Options.debugging?
          
          before_destroy_it
          success = destroy_it unless @errors
          after_destroy_it unless @errors || !success

          puts "Failed destroy with errors=#{@errors.inspect}" if (@errors || !success) && RestfulJson::Options.debugging?
          respond_with (@errors ? @errors || @value)
        end
      end

      # anything that needs to happen before the resource is destroyed
      def before_destroy_it; end
      
      # destroy the specified resource
      def destroy_it
        puts "Attempting to destroy #{@model_class.try(:name)} with id #{params[:id]}" if RestfulJson::Options.debugging?
        @value.where(id: params[:id]).first
        @value ? @model_class.destroy(params[:id]) : true
      end

      # anything that needs to happen after the resource is destroyed
      def after_destroy_it; end

    end
  end
end
