module RestfulJson
  module Controller
    def acts_as_restful_json(options = {})
      send :include, InstanceMethods
      send :before_filter, :sanity_check
      send :after_filter, :cors_set_access_control_headers
    end
    
    module InstanceMethods
      def sanity_check
        puts "Request accepted #{request}"
        puts "params #{params}"
        puts "self #{self}"
        puts "methods #{self.methods.sort.join(', ')}"
        puts "@__restful_json_class=#{@__restful_json_class} methods=#{@__restful_json_class.methods}"
      end

      def initialize
        puts "in class instance"
        puts "self: #{self} object_id=#{self.object_id}"
        puts "self.class: #{self.class} object_id=#{self.class.object_id}"
        puts "self: #{(class << self; self; end)} object_id=#{(class << self; self; end).object_id}"

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
          instance_variable_set("@#{@__restful_json_model_plural}".to_sym, nil)
          instance_variable_set("@#{@__restful_json_model_singular}".to_sym, nil)
          puts "'#{self}' using model class: '#{@__restful_json_class}', attributes: '@#{@__restful_json_model_plural}', '@#{@__restful_json_model_singular}'"
          puts "Immediately before class_eval, @__restful_json_class is #{@__restful_json_class} and object_id=#{@__restful_json_class.object_id}}"
          @__restful_json_initialized = true
        end
      end

      # This borrows heavily from Dan Gebhardt's example at: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
      def restful_json_controller_not_yet_configured?
        unless @__restful_json_initialized
          puts "RestfulJson controller #{self} called before setup, so returning a 503 error."
          puts "#{self}.instance_variable_names: #{self.instance_variable_names}"
          puts "#{self}.inspect: #{self.inspect}"
          respond_to do |format|
            format.json { render json: nil, status: :service_unavailable }
          end
        end
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
      def cors_preflight_check
        unless ENV['RESTFUL_JSON_CORS_GLOBALLY_ENABLED'] || $restful_json_cors_globally_enabled
          if request.method == :options
            headers['Access-Control-Allow-Origin'] =  '*'
            headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
            headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
            headers['Access-Control-Max-Age'] = '1728000'
            # Allow one or more headers to be overriden
            headers.merge!(@__restful_json_options[:cors_preflight_headers])
            # CORS returns as text to the browser as a step before the json, so is intentionally text type and not json.
            render :text => '', :content_type => 'text/plain'
          end
        end
      end

      # For all responses in this controller, return the CORS access control headers.
      # Modified from Tom Sheffler's example in http://www.tsheffler.com/blog/?p=428
      # to allow customization.
      def cors_set_access_control_headers
        unless ENV['RESTFUL_JSON_CORS_GLOBALLY_ENABLED'] || $restful_json_cors_globally_enabled
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

      def get_to_json_options
        # this is a bit nasty and could use a chain of ||= but it is
        # helpful to output the process used for finding the format

        if @__restful_json_class.methods.include?(:get_json_format)
          puts "Looking for a json format... params[:json_format]=#{params[:json_format]}, request.referer=#{request.referer}, params[:controller]=#{params[:controller]}, params[:action]=#{params[:action]}"
          options = json_format(params[:json_format]) if params[:json_format]
          return options if options
          options = json_format("#{request.referer}") if request.referer
          return options if options
          options = json_format("#{params[:controller]}\##{params[:action]}")
          return options if options
          options = json_format(params[:controller])
          return options if options
          options = json_format(params[:action])
          return options if options
          options = json_format('default')
          return options if options
        end

        puts "get_json_format method not defined on #{@__restful_json_class}, so using to_json formatting defaults"
        {}
      end

      def json_format(key)
        options = @__restful_json_class.get_json_format(key.to_sym)
        # only quote-escape symbol if not a valid symbol name without quote-escapes using inspect.
        what_happened = options.nil? ? "did not define a json format for #{key.to_sym.inspect}" : "defined a json format #{key.to_sym.inspect} with options #{options.inspect}"
        puts "#{@__restful_json_class} #{what_happened}"
        options
      end

      # may be overidden in controller to have method-specific access control
      def index_allowed?
        allowed?
      end

      def index
        return if restful_json_controller_not_yet_configured?

        unless index_allowed?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
        end

        cors_preflight_check

        value = JSON.parse(index_it(@__restful_json_class).to_json(get_to_json_options))

        instance_variable_set("@#{@__restful_json_model_plural}".to_sym, value)
        respond_to do |format|
          format.json { render json: {@__restful_json_model_plural.to_sym => value} }
          #json
        end
      end

      def index_it(restful_json_model_class)
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
        value = restful_json_model_class.scoped
        allowed_activerecord_model_attribute_keys.each do |attribute_key|
          param = params[attribute_key]
          value = value.where(attribute_key => param) if param.present?
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
        value
      end

      # may be overidden in controller to have method-specific access control
      def show_allowed?
        allowed?
      end

      def show
        return if restful_json_controller_not_yet_configured?

        unless show_allowed?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
        end

        cors_preflight_check

        puts "@__restful_json_class=#{@__restful_json_class}"
        value = JSON.parse(show_it(@__restful_json_class).to_json(get_to_json_options))

        instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
        respond_to do |format|
          format.json { render json: {@__restful_json_model_singular.to_sym => value} }
        end
      end

      def show_it(restful_json_model_class)
        restful_json_model_class.find(params[:id])
      end

      # may be overidden in controller to have method-specific access control
      def create_allowed?
        allowed?
      end

      # POST /#{model_plural}.json
      def create
        return if restful_json_controller_not_yet_configured?

        unless create_allowed?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
        end

        cors_preflight_check

        value = JSON.parse(create_it(@__restful_json_class).to_json(get_to_json_options))

        instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
        respond_to do |format|
          if @__restful_json_model_singular.save
            # note: status is magic- automatically sets HTTP code to 201 since status is created
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :created, location: value }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: value.errors, status: :unprocessable_entity }
          end
        end
      end

      def create_it(restful_json_model_class, data)
        restful_json_model_class.new(data)
      end

      # may be overidden in controller to have method-specific access control
      def update_allowed?
        allowed?
      end

      # PUT /#{model_plural}/1.json
      def update
        return if restful_json_controller_not_yet_configured?

        unless update_allowed?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
        end

        cors_preflight_check

        value = JSON.parse(update_it(@__restful_json_class).to_json(get_to_json_options))
        
        instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
        respond_to do |format|
          if @__restful_json_model_singular.save
            # note: status is magic- automatically sets HTTP code to 200 since status is ok
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :ok }
          else
            # note: status is magic- automatically sets HTTP code to 422 since status is unprocessable_entity
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: value.errors, status: :unprocessable_entity }
          end
        end
      end

      def update_it(restful_json_model_class, id)
        restful_json_model_class.find(id)
      end

      # may be overidden in controller to have method-specific access control
      def destoy_allowed?
        allowed?
      end

      # DELETE /#{model_plural}/1.json
      def destroy
        return if restful_json_controller_not_yet_configured?

        unless destroy_allowed?
          respond_to do |format|
            # note: status is magic- automatically sets HTTP code to 403 since status is forbidden
            # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
            format.json { render json: nil, status: :forbidden }
          end
        end

        cors_preflight_check

        destroy_it(@__restful_json_class, params[:id])
        respond_to do |format|
          # note: status is magic- automatically sets HTTP code to 200 since status is ok
          # list of codes and symbols here: http://www.codyfauser.com/2008/7/4/rails-http-status-code-to-symbol-mapping/
          format.json { render json: nil, status: :ok }
        end
      end

      def destroy_it(restful_json_model_class, id)
        restful_json_model_class.find(id).destroy
      end
    end
  end
end