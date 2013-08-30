# The restful_json controller module. This module (RestfulJson::Controller) is included on ActionController
# and then each individual controller should call acts_as_restful_json.
#
# Only use acts_as_restful_json in each individual service controller rather than a parent or
# ancestor class of the service controller. class_attribute's are supposed to work when you subclass,
# if you use setters (=, =+ to add to array instead of <<, etc.) but we have seen strange errors
# about missing columns, etc. related to the model_class, etc. being wrong if you share a 
# parent/ancestor class that acts_as_restful_json and then switch back and forth between controllers.
# Why? The controller class overrides the shared class_attribute's when the controller class loads,
# which other than re-loading via Rails autoload, only happens once; so you hit one controller, then the
# the other, it starts overwriting/adding to attributes, and then when you hit the first one again, no
# class method calling on class instantiation is being called, so it is using the wrong model. That is
# bad, so don't do that.
#
module RestfulJson
  module Controller
    extend ::ActiveSupport::Concern

    NILS = ['NULL'.freeze, 'null'.freeze, 'nil'.freeze]
    SINGLE_VALUE_ACTIONS = [:create, :update, :destroy, :show, :new, :edit]

    included do
      # this can be overriden in the controller via defining respond_to
      formats = RestfulJson.formats || ::Mime::EXTENSION_LOOKUP.keys.collect{|m|m.to_sym}
      respond_to(*formats)

      # create class attributes for each controller option and set the value to the value in the app configuration
      class_attribute :model_class, instance_writer: true
      class_attribute :model_singular_name, instance_writer: true
      class_attribute :model_plural_name, instance_writer: true
      class_attribute :param_to_attr_and_arel_predicate, instance_writer: true
      class_attribute :supported_functions, instance_writer: true
      class_attribute :ordered_by, instance_writer: true
      class_attribute :action_to_query, instance_writer: true
      class_attribute :param_to_query, instance_writer: true
      class_attribute :param_to_through, instance_writer: true
      class_attribute :action_to_render_options, instance_writer: true
      class_attribute :query_includes, instance_writer: true
      class_attribute :action_to_query_includes, instance_writer: true

      # use values from config
      RestfulJson::CONTROLLER_OPTIONS.each do |key|
        class_attribute key, instance_writer: true
        self.send("#{key}=".to_sym, RestfulJson.send(key))
      end

      self.param_to_attr_and_arel_predicate ||= {}
      self.supported_functions ||= []
      self.ordered_by ||= []
      self.action_to_query ||= {}
      self.param_to_query ||= {}
      self.param_to_through ||= {}
      self.action_to_render_options ||= {}
      self.action_to_query_includes ||= {}
      self.actions_supporting_params_methods ||= []
    end

    module ClassMethods

      # A whitelist of filters and definition of filter options related to request parameters.
      #
      # If no options are provided or the :using option is provided, defines attributes that are queryable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
      #   can_filter_by :attr_name_1, :attr_name_2 # implied using: [eq] if RestfulJson.can_filter_by_default_using = [:eq] 
      #   can_filter_by :attr_name_1, :attr_name_2, using: [:eq, :not_eq]
      #
      # When :with_query is specified, it will call a supplied lambda. e.g. t is self.model_class.arel_table, q is self.model_class.all, and p is params[:my_param_name]:
      #   can_filter_by :my_param_name, with_query: ->(t,q,p) {...}
      #
      # When :through is specified, it will take the array supplied to through as 0 to many model names following by an attribute name. It will follow through
      # each association until it gets to the attribute to filter by that via ARel joins, e.g. if the model Foobar has an association to :foo, and on the Foo model there is an assocation
      # to :bar, and you want to filter by bar.name (foobar.foo.bar.name):
      #  can_filter_by :my_param_name, through: [:foo, :bar, :name]
      def can_filter_by(*args)
        options = args.extract_options!

        # :using is the default action if no options are present
        if options[:using] || options.size == 0
          predicates = Array.wrap(options[:using] || self.can_filter_by_default_using)
          predicates.each do |predicate|
            predicate_sym = predicate.to_sym
            args.each do |attr|
              attr_sym = attr.to_sym
              self.param_to_attr_and_arel_predicate[attr_sym] = [attr_sym, :eq, options] if predicate_sym == :eq
              self.param_to_attr_and_arel_predicate["#{attr}#{self.predicate_prefix}#{predicate}".to_sym] = [attr_sym, predicate_sym, options]
            end
          end
        end

        if options[:with_query]
          args.each do |with_query_key|
            self.param_to_query[with_query_key.to_sym] = options[:with_query]
          end
        end

        if options[:through]
          args.each do |through_key|
            self.param_to_through[through_key.to_sym] = options[:through]
          end
        end
      end

      # Can specify additional functions in the index, e.g.
      #   supports_functions :skip, :uniq, :take, :count
      def supports_functions(*args)
        args.extract_options! # remove hash from array- we're not using it yet
        self.supported_functions += args
      end

      # Calls .includes(...) on queries. Take a hash of action as symbol to the includes, e.g. to include(:category, :comments):
      #   including :category, :comments
      # or includes({posts: [{comments: :guest}, :tags]}):
      #   including posts: [{comments: :guest}, :tags]
      def including(*args)
        self.query_includes = args
      end

      # Calls .includes(...) only on specified action queries. Take a hash of action as symbol to the includes, e.g.:
      #   includes_for :create, are: [:category, :comments]
      #   includes_for :index, :a_custom_action, are: [posts: [{comments: :guest}, :tags]]
      def includes_for(*args)
        options = args.extract_options!
        args.each do |an_action|
          if options[:are]
            self.action_to_query_includes.merge!({an_action.to_sym => options[:are]})
          else
            raise "#{self.class.name} must supply an :are option with includes_for #{an_action.inspect}"
          end
        end
      end
      
      # Specify a custom query. If action specified does not have a method, it will alias_method index to create a new action method with that query.
      #
      # t is self.model_class.arel_table and q is self.model_class.all, e.g.
      #   query_for :index, is: -> {|t,q| q.where(:status_code => 'green')}
      def query_for(*args)
        options = args.extract_options!
        # TODO: support custom actions to be automaticaly defined
        args.each do |an_action|
          if options[:is]
            self.action_to_query[an_action.to_sym] = options[:is]
          else
            raise "#{self.class.name} must supply an :is option with query_for #{an_action.inspect}"
          end
          unless an_action.to_sym == :index
            alias_method an_action.to_sym, :index
          end
        end
      end

      # Takes an string, symbol, array, hash to indicate order. If not a hash, assumes is ascending. Is cumulative and order defines order of sorting, e.g:
      #   #would order by foo_color attribute ascending
      #   order_by :foo_color
      # or
      #   order_by {:foo_date => :asc}, :foo_color, 'foo_name', {:bar_date => :desc}
      def order_by(args)
        self.ordered_by = (Array.wrap(self.ordered_by) + Array.wrap(args)).flatten.compact.collect {|item|item.is_a?(Hash) ? item : {item.to_sym => :asc}}
      end

      # Associate a non-standard ActiveModel::Serializer for one or more actions, e.g.
      #    serialize_action :index, with: FoosSerializer
      # or
      #    serialize_action :index, :some_custom_action, with: FooSerializer
      # The default functionality of each action is to use serialize for show, each, create, update, and destroy and serialize_each for index and
      # any custom actions created with query_for. To override that, specify the :for option with value as :array or :each:
      #    serialize_action :index, :some_custom_action, with: FoosSerializer, for: :array
      def serialize_action(*args)
        options = args.extract_options!
        args.each do |an_action|
          if options[:with]
            self.action_to_render_options[an_action.to_sym] ||= {}
            self.action_to_render_options[an_action.to_sym]["restful_json_serialization_#{options[:for] && options[:for].to_sym == :array ? 'array' : 'default'}".to_sym] = options[:with]
          else
            raise "#{self.class.name} must supply an :with option with serialize_action #{an_action.inspect}"
          end
        end
      end

      # Use default or custom ActionController::Permitter with one or more actions, e.g.
      #    permit_action :create, :update # this does nothing because it uses permitter_class, e.g. FooPermitter for FoosController
      # or:
      #    permit_action :index, :some_custom_action, with: FoosQueryPermitter
      def permit_action(*args)
        options = args.extract_options!
        args.each do |an_action|
          if options[:with]
            # if key set to nil, it will use the permitter_class method during the action
            self.action_to_permitter[an_action.to_sym] = options[:with]
          end
        end
      end
    end

    # In initialize we:
    # * guess model name, if unspecified, from controller name
    # * define instance variables containing model name
    # * define the (model_plural_name)_url method, needed if controllers are not in the same module as the models
    # Note: if controller name is not based on model name *and* controller is in different module than model, you'll need to
    # redefine the appropriate method(s) to return urls if needed.
    def initialize
      super

      # if not set, use controller classname
      qualified_controller_name = self.class.name.chomp('Controller')
      @model_class = self.model_class || qualified_controller_name.split('::').last.singularize.constantize

      raise "#{self.class.name} failed to initialize. self.model_class was nil in #{self} which shouldn't happen!" if @model_class.nil?
      raise "#{self.class.name} assumes that #{self.model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless @model_class.ancestors.include?(ActiveRecord::Base)

      @model_singular_name = self.model_singular_name || self.model_class.name.underscore
      @model_plural_name = self.model_plural_name || @model_singular_name.pluralize
      @model_at_plural_name_sym = "@#{@model_plural_name}".to_sym
      @model_at_singular_name_sym = "@#{@model_singular_name}".to_sym
      
      # default methods for strong parameters
      @model_plural_name_params_sym = "#{@model_plural_name}_params".to_sym
      @model_singular_name_params_sym = "#{@model_singular_name}_params".to_sym

      @action_to_singular_action_model_params_method = {}
      @action_to_plural_action_model_params_method = {}

      underscored_modules_and_underscored_plural_model_name = qualified_controller_name.gsub('::','_').underscore

      # This is a workaround for controllers that are in a different module than the model only works if the controller's base part of the unqualified name in the plural model name.
      # If the model name is different than the controller name, you will need to define methods to return the right urls.
      class_eval "def #{@model_plural_name}_url;#{underscored_modules_and_underscored_plural_model_name}_url;end" unless @model_plural_name == underscored_modules_and_underscored_plural_model_name
      singularized_underscored_modules_and_underscored_plural_model_name = underscored_modules_and_underscored_plural_model_name
      class_eval "def #{@model_singular_name}_url(record);#{singularized_underscored_modules_and_underscored_plural_model_name}_url(record);end" unless @model_singular_name == singularized_underscored_modules_and_underscored_plural_model_name
    end

    # If Rails 3, returns @model_class.scoped. If not, returns @model_class.all. This helps avoid a deprecation warning.
    def model_class_scoped
      Rails::VERSION::MAJOR == 3 ? @model_class.scoped : @model_class.all
    end

    def convert_request_param_value_for_filtering(attr_sym, value)
      value && NILS.include?(value) ? nil : value
    end

    # Returns self.return_error_data by default. To only return error_data in dev and test, use this:
    # `def enable_long_error?; Rails.env.development? || Rails.env.test?; end`
    def include_error_data?
      self.return_error_data
    end

    # Searches through self.rj_action_rescue_handlers for appropriate handler.
    # self.rj_action_rescue_handlers is an array of hashes where there is key :exception_classes and/or :exception_ancestor_classes
    # along with :i18n_key and :status keys.
    # :exception_classes contains an array of classes to exactly match the exception.
    # :exception_ancestor_classes contains an array of classes that can match an ancestor of the exception.
    # If exception handled, returns hash, hopefully containing keys :i18n_key and :status.
    # Otherwise, returns nil which indicates that this exception should not be handled.
    def exception_handling_data(e)
      self.rj_action_rescue_handlers.each do |handler|
        return handler if (handler.key?(:exception_classes) && handler[:exception_classes].include?(e.class))
        if handler.key?(:exception_ancestor_classes)
          handler[:exception_ancestor_classes].each do |ancestor|
            return handler if e.class.ancestors.include?(ancestor)
          end
        elsif !handler.key?(:exception_classes) && !handler.key?(:exception_ancestor_classes)
          return handler
        end
      end
      nil
    end

    def handle_or_raise(e)
      raise e if self.rj_action_rescue_class.nil?
      handling_data = exception_handling_data(e)
      raise e unless handling_data
      # this is something we intended to rescue, so log it
      logger.error(e)
      # render error only if we haven't rendered response yet
      render_error(e, handling_data) unless @performed_render
    end

    def do_find_model_instance(first_method)
      # to_s as safety measure for vulnerabilities similar to CVE-2013-1854.
      # primary_key array support for composite_primary_keys.
      if @model_class.primary_key.is_a? Array
        c = @model_class
        c.primary_key.each {|pkey|c.where(pkey.to_sym => params[pkey].to_s)}
      else
        c = @model_class.where(@model_class.primary_key.to_sym => params[@model_class.primary_key].to_s)
      end

      c = apply_includes(c)
      @value = c.send first_method
    end

    # Finds model using provided info in params, prior to any permittance,
    # via where()...first.
    #
    # Supports composite_keys.
    def find_model_instance
      do_find_model_instance(:first)
    end

    # Finds model using provided info in params, prior to any permittance,
    # via where()...first! with exception raise if does not exist.
    #
    # Supports composite_keys.
    def find_model_instance!
      do_find_model_instance(:first!)
    end

    def current_action_includes
      self.action_to_query_includes[params[:action].to_sym] || self.query_includes
    end

    def apply_includes(value)
      this_includes = current_action_includes
      if this_includes && this_includes.size > 0
        value = value.includes(*this_includes)
      end
      value
    end

    def allowed_params
      action_sym = params[:action].to_sym
      singular = single_value_response?
      action_specific_params_method = singular ? (@action_to_singular_action_model_params_method[action_sym] ||= "#{action_sym}_#{@model_singular_name}_params".to_sym) : (@action_to_plural_action_model_params_method[action_sym] ||= "#{action_sym}_#{@model_plural_name}_params".to_sym)
      model_name_params_method = singular ? @model_singular_name_params_sym : @model_plural_name_params_sym
      
      if self.actions_that_authorize.include?(action_sym)
        authorize! action_sym, @model_class
      end

      if self.actions_that_permit.include?(action_sym)
        if self.use_permitters
          return permitted_params_using(self.action_to_permitter[action_sym] || permitter_class)
        elsif self.allow_action_specific_params_methods && self.respond_to?(action_specific_params_method, true)
          return __send__(action_specific_params_method)
        elsif self.actions_supporting_params_methods.include?(action_sym)
          if self.respond_to?(model_name_params_method, true)
            return __send__(model_name_params_method)
          elsif defined?(::ActionController::StrongParameters)
            raise "#{self.class.name} needs a method (can be private): #{model_name_params_method}#{self.allow_action_specific_params_methods ? " or #{action_specific_params_method}" : ''}"
          end
        end
      end

      params
    end

    # Renders error using handling data options (where options are probably hash from self.rj_action_rescue_handlers that was matched).
    #
    # If include_error_data? is true, it returns something like the following (with the appropriate HTTP status code via setting appropriate status in respond_do:
    # {"status": "not_found",
    #  "error": "Internationalized error message or e.message",
    #  "error_data": {"type": "ActiveRecord::RecordNotFound", "message": "Couldn't find Bar with id=23423423", "trace": ["backtrace line 1", ...]}
    # }
    #
    # If include_error_data? is false, it returns something like:
    # {"status": "not_found", "error", "Couldn't find Bar with id=23423423"}
    #
    # It handles any format in theory that is supported by respond_to and has a `to_(some format)` method.
    def render_error(e, handling_data)
      use_backtrace_cleaner = handling_data[:clean_backtrace] || true
      i18n_key = handling_data[:i18n_key]
      msg = t(i18n_key, default: e.message)
      status = handling_data[:status] || :internal_server_error
      if include_error_data?
        respond_to do |format|
          format.html { render notice: msg }
          format.any { render request.format.to_sym => {status: status, error: msg, error_data: {type: e.class.name, message: e.message, trace: Rails.backtrace_cleaner.clean(e.backtrace)}}, status: status }
        end
      else
        respond_to do |format|
          format.html { render notice: msg }
          format.any { render request.format.to_sym => {status: status, error: msg}, status: status }
        end
      end
      # return exception so we know it was handled
      e
    end

    def render_or_respond(read_only_action, success_code = :ok)
      if self.render_enabled
        # 404/not found is just for update (not destroy, because idempotent destroy = no 404)
        if success_code == :not_found
          respond_to do |format|
            format.html { render file: "#{Rails.root}/public/404.html", status: :not_found }
            format.any  { head :not_found }
          end
        elsif !@value.nil? && ((read_only_action && RestfulJson.return_resource) || RestfulJson.avoid_respond_with)
          respond_with(@value) do |format|
            format.json do
              if !@value.respond_to?(:errors) || @value.errors.empty?
                result = {json: @value, status: success_code}
                result.merge!(additional_render_or_respond_success_options)
              else
                result = {json: {errors: @value.errors}, status: :unprocessable_entity}
              end
              render result
            end
          end
        else
          if !@value.respond_to?(:errors) || @value.errors.empty?
            respond_with @value, additional_render_or_respond_success_options
          else
            respond_with @value
          end
        end
      else
        @value
      end
    end

    def single_value_response?
      SINGLE_VALUE_ACTIONS.include?(params[:action].to_sym)
    end

    # Returns additional rendering options. By default will massage self.action_to_render_options a little and return that,
    # e.g. if you had used serialize_action to specify an array and each serializer for a specific action, if it is that action,
    # it may return something like: {serializer: MyFooArraySerializer, each_serializer: MyFooSerializer}. If you'd like to do
    # something custom in some situations, but default in others, you may also call default_additional_render_or_respond_success_options
    # from within this method to get the defaults.
    def additional_render_or_respond_success_options
      default_additional_render_or_respond_success_options
    end

    def default_additional_render_or_respond_success_options
      result = {}
      if self.action_to_render_options[params[:action].to_sym]
        custom_action_serializer = self.action_to_render_options[params[:action].to_sym][:restful_json_serialization_default]
        result[(single_value_response? ? :serializer : :each_serializer)] = custom_action_serializer if custom_action_serializer
        custom_action_array_serializer = self.action_to_render_options[params[:action].to_sym][:restful_json_serialization_array]
        result[:serializer] = custom_action_array_serializer if custom_action_array_serializer && !single_value_response?
      end
      result
    end

    # The controller's index (list) method to list resources.
    #
    # Note: this method be alias_method'd by query_for, so it is more than just index.
    def index
      # could be index or another action if alias_method'd by query_for
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      p_params = allowed_params
      t = @model_class.arel_table
      value = model_class_scoped
      custom_query = self.action_to_query[params[:action].to_sym]
      if custom_query
        value = custom_query.call(t, value)
      end

      value = apply_includes(value)

      self.param_to_query.each do |param_name, param_query|
        if params[param_name]
          # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
          value = param_query.call(t, value, p_params[param_name].to_s)
        end
      end

      self.param_to_through.each do |param_name, through_array|
        if p_params[param_name]
          # build query
          # e.g. SomeModel.all.joins({:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}).where(sub_sub_sub_assoc_model_table_name: {column_name: value})
          last_model_class = @model_class
          joins = nil # {:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}
          through_array.each do |association_or_attribute|
            if association_or_attribute == through_array.last
              # must convert param value to string before possibly using with ARel because of CVE-2013-1854, fixed in: 3.2.13 and 3.1.12 
              # https://groups.google.com/forum/?fromgroups=#!msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ
              value = value.joins(joins).where(last_model_class.table_name.to_sym => {association_or_attribute => p_params[param_name].to_s})
            else
              found_classes = last_model_class.reflections.collect {|association_name, reflection| reflection.class_name.constantize if association_name.to_sym == association_or_attribute}.compact
              if found_classes.size > 0
                last_model_class = found_classes[0]
              else
                # bad can_filter_by :through found at runtime
                raise "Association #{association_or_attribute.inspect} not found on #{last_model_class}."
              end

              if joins.nil?
                joins = association_or_attribute
              else
                joins = {association_or_attribute => joins}
              end
            end
          end
        end
      end

      self.param_to_attr_and_arel_predicate.keys.each do |param_name|
        options = param_to_attr_and_arel_predicate[param_name][2]
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854 
        param = p_params[param_name].to_s || options[:with_default]

        if param.present? && param_to_attr_and_arel_predicate[param_name]
          attr_sym = param_to_attr_and_arel_predicate[param_name][0]
          predicate_sym = param_to_attr_and_arel_predicate[param_name][1]
          if predicate_sym == :eq
            value = value.where(attr_sym => convert_request_param_value_for_filtering(attr_sym, param))
          else
            one_or_more_param = param.split(self.filter_split).collect{|v|convert_request_param_value_for_filtering(attr_sym, v)}
            value = value.where(t[attr_sym].try(predicate_sym, one_or_more_param))
          end
        end
      end

      if p_params[:page] && self.supported_functions.include?(:page)
        page = p_params[:page].to_i
        page = 1 if page < 1 # to avoid people using this as a way to get all records unpaged, as that probably isn't the intent?
        #TODO: to_s is hack to avoid it becoming an Arel::SelectManager for some reason which not sure what to do with
        value = value.skip((self.number_of_records_in_a_page * (page - 1)).to_s)
        value = value.take((self.number_of_records_in_a_page).to_s)
      end

      if p_params[:skip] && self.supported_functions.include?(:skip)
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        value = value.skip(p_params[:skip].to_s)
      end

      if p_params[:take] && self.supported_functions.include?(:take)
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        value = value.take(p_params[:take].to_s)
      end

      if p_params[:uniq] && self.supported_functions.include?(:uniq)
        value = value.uniq
      end

      # these must happen at the end and are independent
      if p_params[:count] && self.supported_functions.include?(:count)
        value = value.count.to_i
      elsif p_params[:page_count] && self.supported_functions.include?(:page_count)
        count_value = value.count.to_i # this executes the query so nothing else can be done in AREL
        value = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
      else
        #TODO: also declaratively specify order via order=attr1,attr2, etc. like can_filter_by w/queries, subattrs, and direction.
        self.ordered_by.each do |attr_to_direction|
          # this looks nasty, but makes no sense to iterate keys if only single of each
          value = value.order(t[attr_to_direction.keys[0]].send(attr_to_direction.values[0]))
        end
        value = value.to_a
      end      
      @value = value
      instance_variable_set(@model_at_plural_name_sym, @value)
      render_or_respond(true)
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's show (get) method to return a resource.
    def show
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      @value = find_model_instance!
      # allowed_params used primarily for authorization. can't do this to get id param(s) because those are sent via route, not
      # in wrapped params (if wrapped)
      allowed_params
      instance_variable_set(@model_at_singular_name_sym, @value)
      render_or_respond(true, @value.nil? ? :not_found : :ok)
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's new method (e.g. used for new record in html format).
    def new
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      # allowed_params used primarily for authorization. can't do this to get id param(s) because those are sent via route, not
      # in wrapped params (if wrapped)
      allowed_params
      @value = @model_class.new
      instance_variable_set(@model_at_singular_name_sym, @value)
      render_or_respond(true)
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's edit method (e.g. used for edit record in html format).
    def edit
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      @value = find_model_instance!
      # allowed_params used primarily for authorization. can't do this to get id param(s) because those are sent via route, not
      # in wrapped params (if wrapped)
      allowed_params
      instance_variable_set(@model_at_singular_name_sym, @value)
      @value
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's create (post) method to create a resource.
    def create
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      @value = @model_class.new(allowed_params)
      @value.save
      instance_variable_set(@model_at_singular_name_sym, @value)
      render_or_respond(false, :created)
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's update (put) method to update a resource.
    def update
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      @value = find_model_instance!
      # allowed_params used primarily for authorization. can't do this to get id param(s) because those are sent via route, not
      # in wrapped params (if wrapped)
      p_params = allowed_params
      @value.update_attributes(p_params) unless @value.nil?
      instance_variable_set(@model_at_singular_name_sym, @value)
      render_or_respond(true, @value.nil? ? :not_found : :ok)
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end

    # The controller's destroy (delete) method to destroy a resource.
    def destroy
      logger.debug "#{params[:action]} called in #{self.class}: model=#{@model_class}, request.format=#{request.format}, request.content_type=#{request.content_type}, params=#{params.inspect}" if self.debug
      # don't raise error- DELETE should be idempotent per REST.
      @value = find_model_instance
      # allowed_params used primarily for authorization. can't do this to get id param(s) because those are sent via route, not
      # in wrapped params (if wrapped)
      allowed_params
      @value.destroy if @value
      instance_variable_set(@model_at_singular_name_sym, @value)
      if !@value.respond_to?(:errors) || @value.errors.empty? || (request.format != 'text/html' && request.content_type != 'text/html')
        # don't require a destroy view for success, because it isn't implements in Rails by default for json
        respond_to do |format|
          format.any  { head :ok }
        end
      else
        render_or_respond(false)
      end
    rescue self.rj_action_rescue_class => e
      handle_or_raise(e)
    end
  end
end
