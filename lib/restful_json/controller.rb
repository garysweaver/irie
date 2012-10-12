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

      included do
        # create class attributes for each controller option and set the value to the value in the app configuration
        class_attribute :model_class, instance_writer: true
        class_attribute :model_singular_name, instance_writer: true
        class_attribute :model_plural_name, instance_writer: true
        class_attribute :model_created_message, instance_writer: true
        class_attribute :model_updated_message, instance_writer: true
        class_attribute :param_to_attr_and_arel_predicate, instance_writer: true
        class_attribute :supported_functions, instance_writer: true
        class_attribute :order_by, instance_writer: true
        class_attribute :action_to_query, instance_writer: true

        # use values from config
        # debug uses RestfulJson.debug? because until this is done no local debug class attribute exists to check
        RestfulJson::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true
          puts "set #{key} to #{RestfulJson.send(key)}" if RestfulJson.debug?
          self.send("#{key}=".to_sym, RestfulJson.send(key))
          puts "#{key}=#{self.send(key)}" if RestfulJson.debug?
          puts "#{key}?=#{self.send("#{key}?".to_sym)}" if RestfulJson.debug?
        end

        self.param_to_attr_and_arel_predicate ||= {}
        self.supported_functions ||= []
        self.order_by ||= []
        self.action_to_query ||= {}

        # this can be overriden, but it is restful_json...
        respond_to :json
      end

      module ClassMethods
        # Whitelist attributes that are queryable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
        # can_filter_by :attr_name_1, :attr_name_2 # implied using: [eq] if RestfulJson.can_filter_by_default_using = [:eq] 
        # can_filter_by :attr_name_1, :attr_name_2, using: [:eq, :not_eq]
        def can_filter_by(*args)
          options = args.extract_options!
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

        # Can specify additional functions in the index, e.g.
        # supports_functions :skip, :uniq, :take, :count
        def supports_functions(*args)
          options = args.extract_options! # overkill, sorry
          self.supported_functions += args
        end
        
        # See https://github.com/rails/arel
        # t is self.model_class.arel_table and q is self.model_class.scoped
        # e.g. query_for :index, is: {|t,q| q.where(params[:foo] => 'bar').order(t[])}
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
              puts "#{self.class.name} defining a new method called #{an_action.inspect}" if self.debug?
              alias_method an_action.to_sym, :index
            end
          end
        end
      end

      def initialize
        super

        # if not set, use controller classname
        qualified_controller_name = self.class.name.chomp('Controller')
        @model_class = self.model_class || qualified_controller_name.split('::').last.singularize.constantize
        puts "#{self.class.name} @model_class = #{@model_class.inspect}" if self.debug?

        raise "#{self.class.name} failed to initialize. self.model_class was nil in #{self} which shouldn't happen!" if @model_class.nil?
        raise "#{self.class.name} assumes that #{self.model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless @model_class.ancestors.include?(ActiveRecord::Base)

        @model_singular_name = self.model_singular_name || self.model_class.name.underscore
        puts "#{self.class.name} @model_singular_name = #{@model_singular_name.inspect}" if self.debug?
        @model_plural_name = self.model_plural_name || @model_singular_name.pluralize
        puts "#{self.class.name} @model_plural_name = #{@model_plural_name.inspect}" if self.debug?
        @model_created_message = self.model_created_message|| "#{model_class} was successfully created.".freeze
        puts "#{self.class.name} @model_created_message = #{@model_created_message.inspect}" if self.debug?
        @model_updated_message = self.model_updated_message || "#{model_class} was successfully updated.".freeze
        puts "#{self.class.name} @model_updated_message = #{@model_updated_message.inspect}" if self.debug?
        @model_at_plural_name = "@#{@model_plural_name}".freeze
        puts "#{self.class.name} @model_at_plural_name = #{@model_at_plural_name.inspect}" if self.debug?
        @model_at_plural_name_sym = "@#{@model_plural_name}".to_sym
        puts "#{self.class.name} @model_at_plural_name_sym = #{@model_at_plural_name_sym.inspect}" if self.debug?
        @model_at_singular_name = "@#{@model_singular_name}".freeze
        puts "#{self.class.name} @model_at_singular_name = #{@model_at_singular_name.inspect}" if self.debug?
        @model_at_singular_name_sym = "@#{@model_plural_name}".to_sym
        puts "#{self.class.name} @model_at_singular_name_sym = #{@model_at_singular_name_sym.inspect}" if self.debug?
        @model_plural_name_sym = @model_plural_name.to_sym
        puts "#{self.class.name} @model_plural_name_sym = #{@model_plural_name_sym.inspect}" if self.debug?
        @model_singular_name_sym = model_singular_name.to_sym
        puts "#{self.class.name} @model_singular_name_sym = #{@model_singular_name_sym.inspect}" if self.debug?
        underscored_modules_and_underscored_plural_model_name = qualified_controller_name.gsub('::','_').underscore
        @model_plural_name_url_method_name_sym = "#{underscored_modules_and_underscored_plural_model_name}_url".to_sym
        puts "#{self.class.name} @model_plural_name_url_method_name_sym = #{@model_plural_name_url_method_name_sym.inspect}" if self.debug?
        @model_singular_name_url_method_name_sym = "#{underscored_modules_and_underscored_plural_model_name.singularize}_url".to_sym
        puts "#{self.class.name} @model_singular_name_url_method_name_sym = #{@model_singular_name_url_method_name_sym.inspect}" if self.debug?

        # this workaround for models that are in a different module than the model only works if the controller's base part of the unqualified name in the plural model name
        # if the model name is different than the controller name, you need to define methods to return the right urls

        class_eval "def #{@model_plural_name}_url; #{@model_plural_name_url_method_name_sym}; end"
        class_eval "def #{@model_singular_name}(id); #{@model_singular_name_url_method_name_sym}(id); end"
      end

      def convert_request_param_value_for_filtering(attr_sym, value)
        value && ['NULL','null','nil'].include?(value) ? nil : value
      end

      # this method be alias_method'd by query_for, so it is more than just index
      def index
        t = @model_class.arel_table
        value = @model_class.scoped # returns ActiveRecord::Relation equivalent to select with no where clause

        custom_query = self.action_to_query[params[:action]]
        if custom_query
          puts "using custom query for #{params[:action].inspect} action" if self.debug?
          value = custom_query.proc(t, value)
        else
          self.param_to_attr_and_arel_predicate.keys.each do |param_name|
            options = param_to_attr_and_arel_predicate[param_name][2]
            param = params[param_name] || options[:with_default]
            if param.present? && param_to_attr_and_arel_predicate[param_name]
              puts "applying filter #{param_to_attr_and_arel_predicate[param_name].inspect}" if self.debug?
              attr_sym = param_to_attr_and_arel_predicate[param_name][0]
              predicate_sym = param_to_attr_and_arel_predicate[param_name][1]
              if predicate_sym == :eq
                puts ".where(#{attr_sym.inspect} => convert_request_param_value_for_filtering(#{attr_sym.inspect}, #{param.inspect}))" if self.debug?
                value = value.where(attr_sym => convert_request_param_value_for_filtering(attr_sym, param))
              else
                one_or_more_param = param.split(self.filter_split).collect{|v|convert_request_param_value_for_filtering(attr_sym, v)}
                puts ".where(t[#{attr_sym.inspect}].try(#{predicate_sym.inspect}, #{one_or_more_param.inspect}))" if self.debug?
                value = value.where(t[attr_sym].try(predicate_sym, one_or_more_param))
              end
            end
          end

          if params[:page] && self.supported_functions.include?(:page)
            puts "params[:page] = #{params[:page].inspect}" if self.debug?
            page = params[:page].to_i
            page = 1 if page < 1 # to avoid people using this as a way to get all records unpaged, as that probably isn't the intent?
            #TODO: to_s is hack to avoid it becoming an Arel::SelectManager for some reason which not sure what to do with
            value = value.skip((self.number_of_records_in_a_page * (page - 1)).to_s)
            value = value.take((self.number_of_records_in_a_page).to_s)
          end
          
          if params[:skip] && self.supported_functions.include?(:skip)
            puts "params[:skip] = #{params[:skip].inspect}" if self.debug?
            value = value.skip(params[:skip])
          end
          
          if params[:take] && self.supported_functions.include?(:take)
            puts "params[:take] = #{params[:take].inspect}" if self.debug?
            value = value.take(params[:take])
          end
          
          if params[:uniq] && self.supported_functions.include?(:uniq)
            puts "params[:uniq] = #{params[:uniq].inspect}" if self.debug?
            value = value.uniq
          end

          # these must happen at the end and are independent
          if params[:count] && self.supported_functions.include?(:count)
            puts "params[:count] = #{params[:count].inspect}" if self.debug?
            value = value.count.to_i
          elsif params[:page_count] && self.supported_functions.include?(:page_count)
            puts "params[:page_count] = #{params[:page_count].inspect}" if self.debug?
            count_value = value.count.to_i # this executes the query so nothing else can be done in AREL
            value = (count_value / self.number_of_records_in_a_page) + (count_value % self.number_of_records_in_a_page ? 1 : 0)
          else
            self.order_by.each do |attr_to_direction|
              # TODO: this looks nasty, but makes no sense to iterate keys if only single of each
              puts "ordering by #{attr_to_direction.keys[0].inspect}, #{attr_to_direction.values[0].inspect}" if self.debug?
              value = value.order(t[attr_to_direction.keys[0]].call(attr_to_direction.values[0]))
            end
            value = value.to_a
          end
        end

        @value = value
        instance_variable_set(@model_at_plural_name_sym, @value)

        puts "#{self.class.name}.index responding with #{@value.inspect}, request.format=#{request.format}" if self.debug?
        respond_with @value
      end

      def show
        @value = @model_class.find(params[:id])
        instance_variable_set(@model_at_singular_name_sym, @value)
        puts "#{self.class.name}.show responding with #{@value.inspect}, request.format=#{request.format}" if self.debug?
        respond_with @value
      end

      def new
        @value = @model_class.new
        puts "#{self.class.name}.new responding with #{@value.inspect}, request.format=#{request.format}" if self.debug?
        respond_with @value
      end

      def edit
        @value = @model_class.find(params[:id])
        instance_variable_set(@model_at_singular_name_sym, @value)
      end

      def create
        authorize! :create, @model_class
        puts "#{self.class.name}.create permitted params #{@permitted_params.inspect}, request.format=#{request.format}"
        @value = @model_class.new(permitted_params)
        @value.save
        instance_variable_set(@model_at_singular_name_sym, @value)
        puts "#{self.class.name}.create responding with #{@value.inspect}, request.format=#{request.format}"
        #raise "@value was #{@value.inspect}"
        raise "@model_singular_name_url_method_name_sym=#{@model_singular_name_url_method_name_sym} @value.id=#{@value.id} but not defined" unless defined?(@model_singular_name_url_method_name_sym)
        respond_with @value, location: send(@model_singular_name_url_method_name_sym, @value.id)
      end

      def update
        authorize! :update, @model_class
        @value = @model_class.find(params[:id])
        puts "#{self.class.name}.update permitted params #{@permitted_params.inspect}, request.format=#{request.format}" if self.debug?
        @value.update_attributes(permitted_params)
        instance_variable_set(@model_at_singular_name_sym, @value)
        puts "#{self.class.name}.update responding with #{@value.inspect}, request.format=#{request.format}" if self.debug?
        respond_with @value
      end

      def destroy
        @value = @model_class.find(params[:id])
        @value.destroy
        instance_variable_set(@model_at_singular_name_sym, @value)
        puts "#{self.class.name}.destroy responding with #{@value.inspect}, request.format=#{request.format}" if self.debug?
        respond_with @value
      end
    end
  end
end
