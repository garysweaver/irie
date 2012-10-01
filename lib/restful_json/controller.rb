require 'restful_json/config'
require 'restful_json/concern'
require 'active_model_serializers'
require 'strong_parameters'
require 'convenient-actionpack'

module RestfulJson
  module Controller
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_restful_json(options = {})
        include ActsAsRestfulJson
      end
    end
    
    module ActsAsRestfulJson
      extend ActiveSupport::Concern

      included do
        NEW = 'new'
        EDIT = 'edit'
        send :include, ::ActiveModel::ForbiddenAttributesProtection
        send :include, ::ActionController::Serialization
        send :include, ::ActionController::StrongParameters
        send :include, ::TwinTurbo::Controller
        send :include, ::Convenient::Controller
        #
        #before_filter :before_request
        #after_filter :after_request

        # create class attributes for each controller option and set the value to the value in the app configuration
        class_attribute :model_class, instance_writer: true
        class_attribute :model_singular_name, instance_writer: true
        class_attribute :model_plural_name, instance_writer: true
        class_attribute :model_created_message, instance_writer: true
        class_attribute :model_updated_message, instance_writer: true
        class_attribute :model_at_plural_name_sym, instance_writer: true
        class_attribute :model_plural_name_sym, instance_writer: true
        class_attribute :model_at_plural_name, instance_writer: true
        class_attribute :model_plural_name_url, instance_writer: true
        class_attribute :model_at_singular_name_sym, instance_writer: true
        class_attribute :model_singular_name_sym, instance_writer: true
        class_attribute :model_at_singular_name, instance_writer: true

        # use values from config
        RestfulJson::CONTROLLER_OPTIONS.each do |key|
          class_attribute key, instance_writer: true
          self.send("#{key}=".to_sym, RestfulJson.send(key))
        end
        
        # if not set, use controller classname
        self.model_class ||= self.name.chomp('Controller').split('::').last.singularize.constantize
        self.model_singular_name ||= self.model_class.name.underscore
        self.model_plural_name ||= self.model_singular_name.pluralize

        # set strings that shouldn't have to be set more than at initialization time. this should be done in the setter overrides it isn't working yet.
        self.model_created_message = "#{model_class} was successfully created.".freeze
        self.model_updated_message = "#{model_class} was successfully updated.".freeze
        self.model_at_plural_name = "@#{model_plural_name}".freeze
        self.model_at_plural_name_sym = "@#{model_plural_name}".to_sym
        self.model_at_singular_name = "@#{model_singular_name}".freeze
        self.model_at_singular_name_sym = "@#{model_plural_name}".to_sym
        self.model_plural_name_sym = model_plural_name.to_sym
        self.model_plural_name_url = "#{model_plural_name}_url".freeze
        self.model_singular_name_sym = model_singular_name.to_sym
        
      end

      module ClassMethods
      end

      def model_class=(val)
        raise "Yahoo! model_class= called"
        super
        model_created_message = "#{model_class} was successfully created.".freeze
        model_updated_message = "#{model_class} was successfully updated.".freeze
      end
    
      def model_plural_name=(val)
        raise "Yahoo! model_plural_name= called"
        super
        model_plural_name_sym = model_plural_name.to_sym
        model_at_plural_name = "@#{model_plural_name}".freeze
        model_plural_name_url = "#{model_plural_name}_url".freeze
      end
    
      def model_singular_name=(val)
        raise "Yahoo! model_singular_name= called"
        super
        model_singular_name_sym = model_singular_name.to_sym
        model_at_singular_name = "@#{model_singular_name}".freeze
      end

      def initialize
        raise "#{self.class.name} failed to initialize. self.model_class was nil in #{self} which shouldn't happen!" if self.model_class.nil?
        # note: we are overriding class attribute setters locally to attempt to set strings to allow us to set @foos and @foo without additional string creation per request
        raise "#{self.class.name} assumes that #{self.model_class} extends ActiveRecord::Base, but it didn't. Please fix, or remove this constraint." unless self.model_class.ancestors.include?(ActiveRecord::Base)
        puts "'#{self}' self.model_class=#{self.model_class}, self.model_singular_name=#{self.model_singular_name}, self.model_plural_name=#{self.model_plural_name}" if RestfulJson.debug?
      end

      def index
          instance_variable_set(self.model_at_plural_name_sym, self.model_class.all)
          @value = instance_eval(self.model_at_plural_name)

          respond_to do |format|
            format.html # index.html.erb
            format.json { render json: @value }
          end
      end

      def show
          instance_variable_set(self.model_at_singular_name_sym, self.model_class.find(params[:id]))
          @value = instance_eval(self.model_at_singular_name)

          respond_to do |format|
            format.html # show.html.erb
            format.json { render json: @value }
          end
      end

      def new
          instance_variable_set(self.model_at_singular_name_sym, self.model_class.new)
          @value = instance_eval(self.model_at_singular_name)

          respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @value }
          end
      end

      def edit
          instance_variable_set(self.model_at_singular_name_sym, self.model_class.find(params[:id]))
      end

      def create
          authorize! :create, self.model_class

          puts "self.model_singular_name_sym=#{self.model_singular_name_sym}"
          puts "self.model_at_singular_name=#{self.model_at_singular_name}"
          puts "params[self.model_singular_name_sym]=#{params[self.model_singular_name_sym]}"
          #puts "params[@model_singular_name_sym]=#{params[self.model_singular_name_sym]}"
          instance_variable_set(self.model_at_singular_name_sym, self.model_class.new(params[self.model_singular_name_sym]))
          @value = instance_eval(self.model_at_singular_name)
          puts "@value=#{@value}"

          respond_to do |format|
            if data.save
              format.html { redirect_to @value, notice: self.model_creation_message }
              format.json { render json: @value, status: :created, location: @value }
            else
              format.html { render action: NEW }
              format.json { render json: @value.errors, status: :unprocessable_entity }
            end
          end
      end

      def update
          authorize! :update, self.model_class

          instance_variable_set(self.model_at_singular_name_sym, self.model_class.find(params[:id]))
          @value = instance_eval(self.model_at_singular_name)

          respond_to do |format|
            if @model_class.update_attributes(params[self.model_at_singular_name_sym])
              format.html { redirect_to @model_class, notice: self.model_updated_message }
              format.json { head :no_content }
            else
              format.html { render action: EDIT }
              format.json { render json: @value.errors, status: :unprocessable_entity }
            end
          end
      end

      def destroy
          instance_variable_set(self.model_at_singular_name_sym, @model_class.find(params[:id]))
          @value = instance_eval(self.model_at_singular_name)

          @model_class.destroy

          respond_to do |format|
            format.html { redirect_to instance_eval(self.model_plural_name_url) }
            format.json { head :no_content }
          end
      end
    end
  end
end
