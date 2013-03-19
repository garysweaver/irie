require 'restful_json/config'
require 'twinturbo/controller'
require 'active_model_serializers'
require 'strong_parameters'
require 'cancan'

module RestfulJson
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_restful_json(options = {})
        include ::ActionController::Serialization
        include ::ActionController::StrongParameters
        include ::CanCan::ControllerAdditions
        include ::TwinTurbo::Controller
        include ActsAsRestfulJson
      end
    end
    
    module ActsAsRestfulJson
      extend ActiveSupport::Concern

      NILS = ['NULL','null','nil']

      included do
        # this can be overriden in the controller via defining respond_to
        formats = RestfulJson.formats || Mime::EXTENSION_LOOKUP.keys.collect{|m|m.to_sym}
        respond_to *formats

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

        # use values from config
        # debug uses RestfulJson.debug? because until this is done no local debug class attribute exists to check
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
      end

      module ClassMethods
        # A whitelist of filters and definition of filter options related to request parameters.
        #
        # If no options are provided or the :using option is provided, defines attributes that are queryable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
        #   can_filter_by :attr_name_1, :attr_name_2 # implied using: [eq] if RestfulJson.can_filter_by_default_using = [:eq] 
        #   can_filter_by :attr_name_1, :attr_name_2, using: [:eq, :not_eq]
        #
        # When :with_query is specified, it will call a supplied lambda. e.g. t is self.model_class.arel_table, q is self.model_class.scoped, and p is params[:my_param_name]:
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
          options = args.extract_options! # overkill, sorry
          self.supported_functions += args
        end
        
        # Specify a custom query. If action specified does not have a method, it will alias_method index to create a new action method with that query.
        #
        # t is self.model_class.arel_table and q is self.model_class.scoped, e.g.
        #   query_for :index, is: -> {|t,q| q.where(:status_code => 'green')}
        def query_for(*args)
          options = args.extract_options!
          # TODO: support custom actions to be automaticaly defined
          args.each do |an_action|
            if options[:is]
              self.action_to_query[an_action.to_s] = options[:is]
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
          if args.is_a?(Array)
            self.ordered_by += args
          elsif args.is_a?(Hash)
            self.ordered_by.merge!(args)
          else
            raise ArgumentError.new("order_by takes a hash or array of hashes")
          end
        end
      end

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
        underscored_modules_and_underscored_plural_model_name = qualified_controller_name.gsub('::','_').underscore

        # This workaround for models that are in a different module than the model only works if the controller's base part of the unqualified name in the plural model name.
        # If the model name is different than the controller name, you will need to define methods to return the right urls.
        class_eval "def #{@model_plural_name}_url;#{underscored_modules_and_underscored_plural_model_name}_url;end;def #{@model_singular_name}_url(record);#{underscored_modules_and_underscored_plural_model_name.singularize}_url(record);end"        
      end

      def convert_request_param_value_for_filtering(attr_sym, value)
        value && NILS.include?(value) ? nil : value
      end

      # The controller's index (list) method to list resources.
      #
      # Note: this method be alias_method'd by query_for, so it is more than just index.
      def index
        t = @model_class.arel_table
        value = @model_class.scoped # returns ActiveRecord::Relation equivalent to select with no where clause
        custom_query = self.action_to_query[params[:action].to_s]
        if custom_query
          value = custom_query.call(t, value)
        end

        self.param_to_query.each do |param_name, param_query|
          if params[param_name]
            # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
            value = param_query.call(t, value, params[param_name].to_s)
          end
        end

        self.param_to_through.each do |param_name, through_array|
          if params[param_name]
            # build query
            # e.g. SomeModel.scoped.joins({:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}).where(sub_sub_sub_assoc_model_table_name: {column_name: value})
            last_model_class = @model_class
            joins = nil # {:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}
            through_array.each do |association_or_attribute|
              if association_or_attribute == through_array.last
                # must convert param value to string before possibly using with ARel because of CVE-2013-1854, fixed in: 3.2.13 and 3.1.12 
                # https://groups.google.com/forum/?fromgroups=#!msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ
                value = value.joins(joins).where(last_model_class.table_name.to_sym => {association_or_attribute => params[param_name].to_s})
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
          param = params[param_name] || options[:with_default]
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

        if params[:page] && self.supported_functions.include?(:page)
          page = params[:page].to_i
          page = 1 if page < 1 # to avoid people using this as a way to get all records unpaged, as that probably isn't the intent?
          #TODO: to_s is hack to avoid it becoming an Arel::SelectManager for some reason which not sure what to do with
          value = value.skip((self.number_of_records_in_a_page * (page - 1)).to_s)
          value = value.take((self.number_of_records_in_a_page).to_s)
        end

        if params[:skip] && self.supported_functions.include?(:skip)
          # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
          value = value.skip(params[:skip].to_s)
        end

        if params[:take] && self.supported_functions.include?(:take)
          # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
          value = value.take(params[:take].to_s)
        end

        if params[:uniq] && self.supported_functions.include?(:uniq)
          value = value.uniq
        end

        # these must happen at the end and are independent
        if params[:count] && self.supported_functions.include?(:count)
          value = value.count.to_i
        elsif params[:page_count] && self.supported_functions.include?(:page_count)
          count_value = value.count.to_i # this executes the query so nothing else can be done in AREL
          value = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
        else
          self.ordered_by.each do |attr_to_direction|
            # this looks nasty, but makes no sense to iterate keys if only single of each
            value = value.order(t[attr_to_direction.keys[0]].call(attr_to_direction.values[0]))
          end
          value = value.to_a
        end

        @value = value
        instance_variable_set(@model_at_plural_name_sym, @value)
        respond_with @value
      end

      # The controller's show (get) method to return a resource.
      def show
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        @value = @model_class.find(params[:id].to_s)
        instance_variable_set(@model_at_singular_name_sym, @value)
        respond_with @value
      end

      # The controller's new method (e.g. used for new record in html format).
      def new
        @value = @model_class.new
        respond_with @value
      end

      # The controller's edit method (e.g. used for edit record in html format).
      def edit
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        @value = @model_class.find(params[:id].to_s)
        instance_variable_set(@model_at_singular_name_sym, @value)
      end

      # The controller's create (post) method to create a resource.
      def create
        authorize! :create, @model_class
        @value = @model_class.new(permitted_params)
        @value.save
        instance_variable_set(@model_at_singular_name_sym, @value)
        if RestfulJson.return_resource
          respond_with(@value) do |format|
            format.json do
              if @value.errors.empty?
                render json: @value, status: :created
              else
                render json: {errors: @value.errors}, status: :unprocessable_entity
              end
            end
          end
        else
          respond_with @value
        end
      end

      # The controller's update (put) method to update a resource.
      def update
        authorize! :update, @model_class
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        @value = @model_class.find(params[:id].to_s)
        @value.update_attributes(permitted_params)
        instance_variable_set(@model_at_singular_name_sym, @value)
        if RestfulJson.return_resource
          respond_with(@value) do |format|
            format.json do
              if @value.errors.empty?
                render json: @value, status: :ok
              else
                render json: {errors: @value.errors}, status: :unprocessable_entity
              end
            end
          end
        else
          respond_with @value
        end
      end

      # The controller's destroy (delete) method to destroy a resource.
      def destroy
        # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
        @value = @model_class.find(params[:id].to_s)
        @value.destroy
        instance_variable_set(@model_at_singular_name_sym, @value)
        respond_with @value
      end

    end
  end
end
