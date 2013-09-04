module RestfulJson
  module Controller
    extend ::ActiveSupport::Concern

    NILS = ['NULL'.freeze, 'null'.freeze, 'nil'.freeze]

    included do
      # create class attributes for each controller option
      class_attribute :action_to_query, instance_writer: true
      class_attribute :action_to_query_includes, instance_writer: true
      class_attribute :can_be_ordered_by, instance_writer: true
      class_attribute :default_ordered_by, instance_writer: true
      class_attribute :model_class, instance_writer: true
      class_attribute :model_singular_name, instance_writer: true
      class_attribute :model_plural_name, instance_writer: true      
      class_attribute :param_to_attr_and_arel_predicate, instance_writer: true
      class_attribute :param_to_query, instance_writer: true
      class_attribute :param_to_through, instance_writer: true
      class_attribute :query_includes, instance_writer: true
      class_attribute :supported_functions, instance_writer: true

      # define attributes for config keys and use values from config
      RestfulJson::CONTROLLER_OPTIONS.each do |key|
        class_attribute key, instance_writer: true
        self.send("#{key}=".to_sym, RestfulJson.send(key))
      end
      
      self.action_to_query ||= {}
      self.action_to_query_includes ||= {}
      self.can_be_ordered_by ||= []
      self.default_ordered_by ||= []
      self.function_param_names = {}      
      self.param_to_attr_and_arel_predicate ||= {}
      self.param_to_query ||= {}
      self.param_to_through ||= {}
      self.supported_functions ||= []
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

      # A whitelist of orderable attributes.
      #
      # If no options are provided or the :using option is provided, defines attributes that are orderable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
      #   can_order_by :attr_name_1, :attr_name_2
      # So that you could call: http://.../foobars?order=attr_name_1,-attr_name_2
      # to order by attr_name_1 asc then attr_name_2 desc.
      #
      # When :through is specified, it will take the array supplied to through as 0 to many model names following by an attribute name. It will follow through
      # each association until it gets to the attribute to filter by that via ARel joins, e.g. if the model Foobar has an association to :foo, and on the Foo model there is an assocation
      # to :bar, and you want to order by bar.name (foobar.foo.bar.name):
      #  can_order_by :my_param_name, through: [:foo, :bar, :name]
      def can_order_by(*args)
        options = args.extract_options!

        args.each do |arg|
          # store as strings because we have to do a string comparison later to avoid req param symbol attack
          self.can_be_ordered_by << arg.to_s unless self.can_be_ordered_by.include?(arg.to_s)
        end

        # This does the same as the through in can_filter_by: it just sets up joins in the index action.
        if options[:through]
          args.each do |through_key|
            self.param_to_through[through_key.to_sym] = options[:through]
          end
        end
      end

      # Takes an string, symbol, array, hash to indicate order. If not a hash, assumes is ascending. Is cumulative and order defines order of sorting, e.g:
      #   #would order by foo_color attribute ascending
      #   default_order :foo_color
      # or
      #   default_order {:foo_date => :asc}, :foo_color, 'foo_name', {:bar_date => :desc}
      def default_order(args)
        self.default_ordered_by = (Array.wrap(self.default_ordered_by) + Array.wrap(args)).flatten.compact.collect {|item|item.is_a?(Hash) ? item : {item.to_sym => :asc}}
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

    # By default this converts request parameter filter values 'NULL', 'null', 'nil' to nil.
    # This is what converts passed in filter values, so could override to parse other date
    # format, etc.
    def convert_request_param_value_for_filtering(attr_sym, value)
      value && NILS.include?(value) ? nil : value
    end

    def find_model_instance_with(aparams, first_sym)
      # to_s as safety measure for vulnerabilities similar to CVE-2013-1854.
      # primary_key array support for composite_primary_keys.
      if @model_class.primary_key.is_a? Array
        c = @model_class
        c.primary_key.each {|pkey|c.where(pkey.to_sym => aparams[pkey].to_s)}
      else
        c = @model_class.where(@model_class.primary_key.to_sym => aparams[@model_class.primary_key].to_s)
      end

      apply_includes(c).send first_sym
    end

    # Finds model using provided info in provided allowed params,
    # via where(...).first.
    #
    # Supports composite_keys.
    def find_model_instance(aparams)
      find_model_instance_with(aparams, :first)
    end

    # Finds model using provided info in provided allowed params,
    # via where(...).first! (raise exception if not found).
    #
    # Supports composite_keys.
    def find_model_instance!(aparams)
      find_model_instance_with(aparams, :first!)
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

    # The controller's index (list) method to list resources.
    def index
      aparams = params_for_index
      t = @model_class.arel_table
      value = @model_class.all
      custom_query = self.action_to_query[params[:action].to_sym]
      if custom_query
        value = custom_query.call(t, value)
      end

      value = apply_includes(value)

      self.param_to_query.each do |param_name, param_query|
        if aparams[param_name]
          # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
          value = param_query.call(t, value, aparams[param_name].to_s)
        end
      end

      self.param_to_through.each do |param_name, through_array|
        if aparams[param_name]
          # build query
          # e.g. SomeModel.all.joins({:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}).where(sub_sub_sub_assoc_model_table_name: {column_name: value})
          last_model_class = @model_class
          joins = nil # {:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}
          through_array.each do |association_or_attribute|
            if association_or_attribute == through_array.last
              # must convert param value to string before possibly using with ARel because of CVE-2013-1854, fixed in: 3.2.13 and 3.1.12 
              # https://groups.google.com/forum/?fromgroups=#!msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ
              value = value.joins(joins).where(last_model_class.table_name.to_sym => {association_or_attribute => aparams[param_name].to_s})
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
        param = aparams[param_name].to_s || options[:with_default]

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

      if self.supported_functions.include?(:page)
        page_param_names = Array.wrap(self.function_param_names[:page] || :page)
        page_param_names.each do |page_param_name|
          page_param = aparams[page_param_name]
          if page_param
            page = page_param.to_i
            page = 1 if page < 1 # to avoid people using this as a way to get all records unpaged, as that probably isn't the intent?
            #TODO: to_s is hack to avoid it becoming an Arel::SelectManager for some reason which not sure what to do with
            value = value.skip((self.number_of_records_in_a_page * (page - 1)).to_s)
            value = value.take((self.number_of_records_in_a_page).to_s)
          end
        end
      end

      if self.supported_functions.include?(:skip)
        skip_param_names = Array.wrap(self.function_param_names[:skip] || :skip)
        skip_param_names.each do |skip_param_name|
          skip_param = aparams[skip_param_name]
          if skip_param
            # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
            value = value.skip(skip_param.to_s)
          end
        end
      end

      if self.supported_functions.include?(:take)
        take_param_names = Array.wrap(self.function_param_names[:take] || :take)
        take_param_names.each do |take_param_name|
          take_param = aparams[take_param_name]
          if take_param
            # to_s as safety measure for vulnerabilities similar to CVE-2013-1854
            value = value.take(take_param.to_s)
          end
        end
      end
      
      if self.supported_functions.include?(:uniq)
        uniq_param_names = Array.wrap(self.function_param_names[:uniq] || :uniq)
        uniq_param_names.each do |uniq_param_name|
          uniq_param = aparams[uniq_param_name]
          if uniq_param
            value = value.uniq
          end
        end
      end

      # these must happen at the end and are independent
      stop_building_query = false

      # assuming this is first so we won't worry about checking stop_building_query
      if self.supported_functions.include?(:count)
        count_param_names = Array.wrap(self.function_param_names[:count] || :count)
        count_param_names.each do |count_param_name|
          count_param = aparams[count_param_name]
          if count_param
            value = value.count.to_i
            stop_building_query = true
          end
        end
      end

      if !stop_building_query && self.supported_functions.include?(:page_count)
        page_count_param_names = Array.wrap(self.function_param_names[:page_count] || :page_count)
        page_count_param_names.each do |page_count_param_name|
          page_count_param = aparams[page_count_param_name]
          if page_count_param
            count_value = value.count.to_i # this executes the query so nothing else can be done in AREL
            value = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
            stop_building_query = true
          end
        end
      end

      if !stop_building_query
        already_ordered_by = []
        # assuming this is last so we won't worry about setting stop_building_query again.
        order_param_names = Array.wrap(self.function_param_names[:order] || :order)
        order_param_names.each do |order_param_name|
          orig_order_param = aparams[order_param_name]
          if orig_order_param
            order_params = orig_order_param.split(self.filter_split)
            order_params.each do |individual_order_param|
              # remove optional preceding - or + to act as directional
              direction = :asc
              if individual_order_param[0] == '-'
                direction = :desc
                individual_order_param = individual_order_param.reverse.chomp('-').reverse
              elsif individual_order_param[0] == '+'
                individual_order_param = individual_order_param.reverse.chomp('+').reverse
              end
              # order of logic here is important:
              # do not to_sym the partial param value until passes whitelist to avoid symbol attack
              if self.can_be_ordered_by.include?(individual_order_param) && !already_ordered_by.include?(individual_order_param.to_sym)                
                value = value.order(individual_order_param.to_sym => direction)
                already_ordered_by << individual_order_param.to_sym
              end
            end
          end
        end

        self.default_ordered_by.each do |attr_to_direction|
          attr_key = attr_to_direction.keys[0].to_sym
          direction = attr_to_direction.values[0].to_sym
          if !already_ordered_by.include?(attr_key)
            value = value.order(attr_key => direction)
            already_ordered_by << attr_key
          end
        end
      end

      render_index instance_variable_set(@model_at_plural_name_sym, value.to_a)
    end

    def params_for_index
      params
    end

    def render_index(value)
      value
    end

    # The controller's show (get) method to return a resource.
    def show
      aparams = params_for_show
      value = find_model_instance!(aparams)
      render_show instance_variable_set(@model_at_singular_name_sym, value)
    end

    def params_for_show
      params
    end

    def render_show(value)
      value
    end

    # The controller's new method (e.g. used for new record in html format).
    def new
      render_new instance_variable_set(@model_at_singular_name_sym, @model_class.new)
    end

    def render_new(value)
      value
    end

    # The controller's edit method (e.g. used for edit record in html format).
    def edit
      aparams = params_for_edit
      value = find_model_instance!(aparams)
      render_edit instance_variable_set(@model_at_singular_name_sym, value)
    end

    def params_for_edit
      params
    end

    def render_edit(value)
      value
    end

    # The controller's create (post) method to create a resource.
    def create
      aparams = params_for_create
      value = @model_class.new(aparams)
      value.save
      render_create instance_variable_set(@model_at_singular_name_sym, value)
    end

    def params_for_create
      __send__(@model_singular_name_params_sym)
    end

    def render_create(value)
      value.respond_to?(:errors) && value.errors.size > 0 ? render_validation_errors(value) : respond_with(value, status: :created, location: @value)
    end

    # The controller's update (put) method to update a resource.
    def update
      aparams = params_for_update
      value = find_model_instance!(aparams)
      value.update_attributes(aparams) unless value.nil?
      render_update instance_variable_set(@model_at_singular_name_sym, value)
    end

    def params_for_update
      __send__(@model_singular_name_params_sym)
    end

    def render_update(value)
      value.respond_to?(:errors) && value.errors.size > 0 ? render_validation_errors(value) : render(status: :no_content)
    end

    # The controller's destroy (delete) method to destroy a resource.
    # RESTful delete is idempotent, i.e. does not fail if the record does not exist.
    def destroy
      aparams = params_for_destroy
      value = find_model_instance(aparams)
      value.destroy if value
      render_destroy instance_variable_set(@model_at_singular_name_sym, value)
    end

    def params_for_destroy
      params
    end

    def render_destroy(value)
      value
    end

    def render_validation_errors(value)
      #TODO: bad test request format?
      content_type = request.formats.first.to_s.reverse.split('/')[0].split('-')[0].reverse
      # use implicit rendering for html if html or we don't know
      return value if request.format.html?
      # Rails 4.0.0 still punts in validation error handling. :(
      # This probably won't work.
      respond_to do |format|
        format.any { render content_type.to_sym => { errors: value.errors }, status: 422 }
      end
    end
  end
end
