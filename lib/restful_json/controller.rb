module RestfulJson
  module Controller
    @@__as_json_includes_and_accepts_nested_attributes_for=[]

    # Generated from Arel::Predications.public_instance_methods.collect{|c|c.to_s}.sort. To lockdown a little, defining these specifically.
    # See: https://github.com/rails/arel/blob/master/lib/arel/predications.rb
    SUPPORTED_AREL_PREDICATIONS = ['does_not_match', 'does_not_match_all', 'does_not_match_any', 'eq', 'eq_all', 'eq_any', 'gt', 'gt_all', 
                                   'gt_any', 'gteq', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt', 'lt_all', 'lt_any', 'lteq', 
                                   'lteq_all', 'lteq_any', 'matches', 'matches_all', 'matches_any', 'not_eq', 'not_eq_all', 'not_eq_any', 
                                   'not_in', 'not_in_all', 'not_in_any']

    SUPPORTED_AREL_PREDICATIONS_THAT_SPLIT_VALUE = ['does_not_match_all', 'does_not_match_any', 'eq_all', 'eq_any', 'gt_all', 
                                   'gt_any', 'gteq_all', 'gteq_any', 'in', 'in_all', 'in_any', 'lt_all', 'lt_any', 
                                   'lteq_all', 'lteq_any', 'matches_all', 'matches_any', 'not_eq_all', 'not_eq_any', 
                                   'not_in', 'not_in_all', 'not_in_any']

    def acts_as_restful_json(options = {})
      send :include, InstanceMethods
      send :before_filter, :sanity_check
      send :after_filter, :cors_set_access_control_headers
    end
    
    module InstanceMethods

      # as method so can be overriden
      def supported_arel_predications(attr_name=nil)
        SUPPORTED_AREL_PREDICATIONS
      end

      # as method so can be overriden
      def arel_predication_split
        '!'
      end

      # as method so can be overriden
      def convert_request_param_value_for_filtering(attr_name, value)
        value && ['NULL','null','nil'].include?(value) ? nil : value
      end
      
      # as method so can be overriden
      def multiple_value_arel_predications(attr_name=nil)
        SUPPORTED_AREL_PREDICATIONS_THAT_SPLIT_VALUE
      end

      # as method so can be overriden
      def value_split
        ','
      end

      def restful_json_wrapped
        ENV['RESTFUL_JSON_WRAPPED'] || $restful_json_wrapped
      end

      def restful_json_cors_enabled
        ENV['RESTFUL_JSON_CORS_GLOBALLY_ENABLED'] || $restful_json_cors_globally_enabled
      end

      def request_json
        if restful_json_wrapped
          params[@__restful_json_model_singular]
        else
          "#{request.body.read}"
        end
      end

      def single_response_json(value)
        if restful_json_wrapped
          {@__restful_json_model_singular.to_sym => value}
        else
          value
        end
      end

      def plural_response_json(value)
        if restful_json_wrapped
          {@__restful_json_model_plural.to_sym => value}
        else
          value
        end
      end

      def sanity_check
        puts "Request accepted #{request}"
        #puts "params #{params}"
        #puts "self #{self}"
        #puts "methods #{self.methods.sort.join(', ')}"
        #puts "@__restful_json_class=#{@__restful_json_class} methods=#{@__restful_json_class.methods}"
        puts "form_authenticity_token=#{form_authenticity_token}"
        puts "If you get the error: 'WARNING: Can't verify CSRF token authenticity', then put this in your layout or page if using jQuery: $(document).ajaxSend(function(e, xhr, options) {var token = $(\"meta[name='csrf-token']\").attr(\"content\");xhr.setRequestHeader(\"X-CSRF-Token\", token);});"
      end

      def initialize
        #puts "in class instance"
        #puts "self: #{self} object_id=#{self.object_id}"
        #puts "self.class: #{self.class} object_id=#{self.class.object_id}"
        #puts "self: #{(class << self; self; end)} object_id=#{(class << self; self; end).object_id}"
        autodetermine_model_class
      end

      def autodetermine_model_class
        unless @__restful_json_initialized
          @__restful_json_model_singular = self.class.name.chomp('Controller').split('::').last.singularize
          puts "@__restful_json_model_singular=#{@__restful_json_model_singular}"
          @__restful_json_model_plural = @__restful_json_model_singular.pluralize
          puts "@__restful_json_model_plural=#{@__restful_json_model_plural}"
          @__restful_json_class = @__restful_json_model_singular.constantize
          puts "@__restful_json_class=#{@__restful_json_class}"

          raise "#{self.class.name} assumes that #{@__restful_json_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless @__restful_json_class.ancestors.include?(ActiveRecord::Base)
          
          # how we'd initialize if we needed to reference in a view
          #instance_variable_set("@#{@__restful_json_model_plural}".to_sym, nil)
          #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, nil)

          puts "'#{self}' using model class: '#{@__restful_json_class}', attributes: '@#{@__restful_json_model_plural}', '@#{@__restful_json_model_singular}'"
          #puts "Immediately before class_eval, @__restful_json_class is #{@__restful_json_class} and object_id=#{@__restful_json_class.object_id}}"
          @__restful_json_initialized = true
        end
      end

      # This borrows heavily from Dan Gebhardt's example at: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
      def restful_json_controller_not_yet_configured?
        unless @__restful_json_initialized
          puts "RestfulJson controller #{self} called before setup, so returning a 503 error."
          respond_to do |format|
            format.json { render json: nil, status: :service_unavailable }
          end
          return true
        end
        false
      end

      def allowed_activerecord_model_attribute_keys
        # Solution from Jeffrey Chupp (a.k.a. 'semanticart') in http://stackoverflow.com/a/1526328/178651
        @__restful_json_class.new.attributes.keys - @__restful_json_class.protected_attributes.to_a
      end

      def restful_json_controller_not_yet_configured?
        # this doesn't apply here
        false
      end

      # If this is a preflight OPTIONS request, then short-circuit the
      # request, return only the necessary headers and return an empty
      # text/plain. Modified from Tom Sheffler's example in 
      # http://www.tsheffler.com/blog/?p=428 to allow customization.
      def cors_preflight_check?
        unless restful_json_cors_enabled
          if request.method == :options
            puts "CORS preflight check"
            headers['Access-Control-Allow-Origin'] =  '*'
            headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
            headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
            headers['Access-Control-Max-Age'] = '1728000'
            # Allow one or more headers to be overriden
            headers.merge!(@__restful_json_options[:cors_preflight_headers])
            # CORS returns as text to the browser as a step before the json, so is intentionally text type and not json.
            render :text => '', :content_type => 'text/plain'
            return true
          end
        end
        false
      end

      # For all responses in this controller, return the CORS access control headers.
      # Modified from Tom Sheffler's example in http://www.tsheffler.com/blog/?p=428
      # to allow customization.
      def cors_set_access_control_headers
        unless restful_json_cors_enabled
          headers['Access-Control-Allow-Origin'] = '*'
          headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
          headers['Access-Control-Max-Age'] = '1728000'
          # Allow one or more headers to be overriden
          headers.merge!(@__restful_json_options[:cors_access_control_headers])
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
        options[:restful_json_include] = params[:include].split(value_split).collect{|s|s.to_sym} if params[:include]
        options[:restful_json_no_includes] = true if params[:no_includes]
        options[:restful_json_only] = params[:only].split(value_split).collect{|s|s.to_sym} if params[:only]
        # this is a collection to avoid circular references
        options[:restful_json_ancestors] = []
        options
      end

      # may be overidden in controller to have method-specific access control
      def index_allowed?
        allowed?
      end

      def index
        return if restful_json_controller_not_yet_configured?

        unless index_allowed?
          puts "user not allowed to call index on #{self.class.name}"
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end

        return if cors_preflight_check?

        #puts "json_options=#{json_options.inspect}"

        #value = index_it(@__restful_json_class).as_json(json_options)
        #puts "JSON.parse(#{value})"
        #value = JSON.parse(data_string)
        #puts "equals #{value}"

        index_it(@__restful_json_class)

        # how we'd set if we needed to reference in a view by its common plural name
        #instance_variable_set("@#{@__restful_json_model_plural}".to_sym, @value)

        # ember-data:
        #format.json { render json: {@__restful_json_model_plural.to_sym => @value} }
        # angular:

        respond_to do |format|
          format.json { render json: plural_response_json(@value.try(:as_json, json_options)) }
        end
      end

      def index_it(restful_json_model_class=nil)
        # TODO: continue to explore filtering, etc. and look into extension of this project to use Sunspot/SOLR.
        # TODO: Darrel Miller/Ted M. Young suggest reviewing these: http://stackoverflow.com/a/4028874/178651
        #       http://www.ietf.org/rfc/rfc3986.txt  http://tools.ietf.org/html/rfc6570
        # TODO: Paging. Eugen Paraschiv (a.k.a. baeldung) has a good post here, even though is in context of Spring:
        #       http://www.baeldung.com/2012/01/18/rest-pagination-in-spring/
        #       http://www.iana.org/assignments/link-relations/link-relations.
        #       More on Link header: http://blog.steveklabnik.com/posts/2011-08-07-some-people-understand-rest-and-http
        #       example of Link header:
        #       Link: </path/to/resource?other_params_go_here&page=2>; rel="next", </path/to/resource?other_params_go_here&page=9999>; rel="last"
        #       will_paginate looks like it might be a good match

        # Using scoped and separate wheres if params present similar to solution provided by
        # John Gibb in http://stackoverflow.com/a/5820947/178651
        t = restful_json_model_class.arel_table
        value = restful_json_model_class.scoped
        # if "only" request param specified, only return those fields- this is important for uniq to be useful
        if params[:only]
          value.select(params[:only].split(value_split).collect{|s|s.to_sym})
        end

        # handle foo=bar, foo^eq=bar, foo^gt=bar, foo^gteq=bar, etc.
        allowed_activerecord_model_attribute_keys.each do |attribute_key|
          puts "Finding #{restful_json_model_class}"
          value = value.where(attribute_key => convert_request_param_value_for_filtering(param)) if param.present?
          # supported AREL predications are suffix of ^ and predication in the parameter name
          supported_arel_predications.each do |arel_predication|
            param = params["#{attribute_key}#{arel_predication_split}#{arel_predication}"]
            if param.present?
              one_or_more_param = multiple_value_arel_predications.include?(arel_predication) ? param.split(value_split).collect{|v|convert_request_param_value_for_filtering(v)} : convert_request_param_value_for_filtering(param)
              puts ".where(value[#{attribute_key.to_sym.inspect}].call(#{arel_predication.to_sym.inspect}, '#{one_or_more_param}'))"
              value = value.where(t[attribute_key.to_sym].try(arel_predication.to_sym, one_or_more_param))
            end
          end
        end

        # AREL equivalent of SQL OFFSET
        if params[:skip]
          value = value.take(params[:skip])
        end

        # AREL equivalent of SQL LIMIT
        if params[:take]
          value = value.take(params[:take])
        end

        # ?uniq= will return unique records
        if params[:uniq]
          value = value.uniq
        end
        # Sorts can either be specified by sortby=color&sortby=shape or comma-delimited like sortby=color,shape, or some combination.
        # The order in the url is the opposite of the order applied, so first sort param is dominant.
        # Sort direction can be specified across all sorts in the request by sort=asc or sort=desc, or the sort can be specified by
        # + or - at the beginning of the sortby, like sortby=+color,-shape to specify ascending sort on color and descending sort on
        # shape.
        #sortby=params[:sortby]
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

      # may be overidden in controller to have method-specific access control
      def show_allowed?
        allowed?
      end

      def show
        return if restful_json_controller_not_yet_configured?

        unless show_allowed?
          puts "user not allowed to call show on #{self.class.name}"
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end

        return if cors_preflight_check?

        #puts "@__restful_json_class=#{@__restful_json_class}"
        #value = JSON.parse(show_it(@__restful_json_class).as_json(json_options))

        show_it(@__restful_json_class)
        
        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)

        respond_to do |format|
          # ember-data:
          #format.json { render json: {@__restful_json_model_singular.to_sym => value} }
          # angular:
          format.json { render json: single_response_json(@value.try(:as_json, json_options)) }
        end
      end

      def show_it(restful_json_model_class=nil)
        puts "Attempting to show #{restful_json_model_class.try(:name)} with id #{params[:id]}"
        # could just return value, but trying to be consistent with create/update that need to return flag of success
        @value = restful_json_model_class.find(params[:id])
      end

      # may be overidden in controller to have method-specific access control
      def create_allowed?
        allowed?
      end

      # POST /#{model_plural}.json
      def create
        return if restful_json_controller_not_yet_configured?

        unless create_allowed?
          puts "user not allowed to call create on #{self.class.name}"
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end

        return if cors_preflight_check?

        success = create_it(@__restful_json_class)
        
        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)

        respond_to do |format|
          if success
            # note: status is magic- automatically sets HTTP code to 201 since status is created
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            # ember-data:
            #format.json { render json: {@__restful_json_model_singular.to_sym => @value}, status: :created, location: @value }
            # angular:
            format.json { render json: single_response_json(@value.try(:as_json, json_options)), status: :created, location: @value.as_json(json_options) }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @value.errors, status: :unprocessable_entity }
          end
        end
      end

      def create_it(restful_json_model_class=nil)
        json = request_json
        puts "Attempting #{restful_json_model_class.name}.new with request body #{json}"
        parsed_and_converted_json = parse_and_convert_json(restful_json_model_class, json)
        puts "Original JSON.parse(json) was #{JSON.parse(json)}"
        puts "Keyfixed JSON.parse(json) was #{converted_json}"
        @value = restful_json_model_class.new(parsed_and_converted_json)
        @value.save
      end

      # may be overidden in controller to have method-specific access control
      def update_allowed?
        allowed?
      end

      # PUT /#{model_plural}/1.json
      def update
        return if restful_json_controller_not_yet_configured?

        unless update_allowed?
          puts "user not allowed to call update on #{self.class.name}"
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end

        return if cors_preflight_check?

        success = update_it(@__restful_json_class)
        
        # how we'd set if we needed to reference in a view
        #instance_variable_set("@#{@__restful_json_model_singular}".to_sym, @value)

        respond_to do |format|
          if success
            # note: status is magic- automatically sets HTTP code to 200 since status is ok
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            # ember-data:
            # format.json { render json: {@__restful_json_model_singular.to_sym => @value}, status: :ok }
            # angular:
            format.json { render json: single_response_json(@value.try(:as_json, json_options)), status: :ok }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: @value.try(:errors), status: :unprocessable_entity }
          end
        end
      end

      def update_it(restful_json_model_class=nil)
        @value = restful_json_model_class.find(params[:id])
        json = request_json
        puts "Attempting #{restful_json_model_class.name}.update_attributes with request body #{json}"
        parsed_and_converted_json = parse_and_convert_json(restful_json_model_class, json)
        puts "Original JSON.parse(json) was #{JSON.parse(json)}"
        puts "Keyfixed JSON.parse(json) was #{converted_json}"
        success = @value.update_attributes(parsed_and_converted_json)
        success
      end

      # may be overidden in controller to have method-specific access control
      def destroy_allowed?
        allowed?
      end

      # DELETE /#{model_plural}/1.json
      def destroy
        return if restful_json_controller_not_yet_configured?

        unless destroy_allowed?
          puts "user not allowed to call destroy on #{self.class.name}"
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
          return
        end

        return if cors_preflight_check?

        destroy_it(@__restful_json_class)
        respond_to do |format|
          # note: status is magic- automatically sets HTTP code to 200 since status is ok
          # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
          format.json { render json: nil, status: :ok }
        end
      end

      def destroy_it(restful_json_model_class=nil)
        puts "Attempting to destroy #{restful_json_model_class.try(:name)} with id #{params[:id]}"
        restful_json_model_class.where(id: params[:id]).first ? restful_json_model_class.destroy(params[:id]) : true
      end

      # Because most of the time having to specify (name)_attributes as the name of a key in the incoming json is a pain,
      # we'll change each key (name) to (name)_attributes if it is a name. Recurses the provided json, outputting a
      # a hash with the key names "fixed".
      def parse_and_convert_json(clazz, value)
        puts "In parse_and_convert_json(#{clazz}, #{value})"

        # append _attributes to association key names to make using 

        value = JSON.parse(value)
        
        if value.is_a?(Array)
          return value.collect{|v|parse_and_convert_json(clazz, v)}
        elsif value.is_a?(Hash)
          result = {}
          association_name_sym_to_class = {}
          clazz.reflect_on_all_associations.each do |association|
            association_name_sym_to_class[association.name] = association.class_name.constantize
          end
          value.keys.each do |key|
            if association_name_sym_to_class.keys.include?(key.to_sym)
              result["#{key}_attributes".to_sym] = parse_and_convert_json(association_name_sym_to_class[key.to_sym], value[key])
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