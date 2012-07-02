class RestfulJson::BaseController < ApplicationController

  # note: model_class can be fully-qualified like MyModule::MySubModule::MyClass
  def self.restful_json_model(model_class)
    #puts "Configuring #{self.name} with RESTful JSON services for #{model_class.inspect}"

    # is_a? doesn't work with classes 
    raise "restful_json_model must be called with a model class that extends ActiveRecord::Base" unless model_class.ancestors.include?(ActiveRecord::Base)
    # this works whether or not the class is in a defined module
    unqualified_model_classname = model_class.name.split("::").first
    model_singular = unqualified_model_classname.underscore
    model_plural = model_singular.pluralize
    qualified_model_classname = model_class.name
    puts "'#{self.name}' using model class: '#{model_class.name}', attributes: '@#{model_plural}', '@#{model_singular}'"
    definition = <<-eos
      # -- start definition

      # This borrows heavily from Dan Gebhardt's example at: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb

      # GET /#{model_plural}
      # GET /#{model_plural}.json
      def index
        @#{model_plural} = #{qualified_model_classname}.all

        respond_to do |format|
          format.json { render json: {#{model_plural}: @#{model_plural}} }
        end
      end

      # GET /#{model_plural}/1.json
      def show
        @#{model_singular} = #{qualified_model_classname}.find(params[:id])

        respond_to do |format|
          format.json { render json: {#{model_singular}: @#{model_singular}} }
        end
      end

      # POST /#{model_plural}.json
      def create
        @#{model_singular} = #{qualified_model_classname}.new(params[:#{model_singular}])

        respond_to do |format|
          if @#{model_singular}.save
            format.json { render json: {#{model_singular}: @#{model_singular}}, status: :created, location: @#{model_singular} }
          else
            format.json { render json: @#{model_singular}.errors, status: :unprocessable_entity }
          end
        end
      end

      # PUT /#{model_plural}/1.json
      def update
        @#{model_singular} = #{qualified_model_classname}.find(params[:id])

        respond_to do |format|
          if @#{model_singular}.update_attributes(params[:#{model_singular}])
            format.json { render json: {#{model_singular}: @#{model_singular}}, status: :ok }
          else
            format.json { render json: @#{model_singular}.errors, status: :unprocessable_entity }
          end
        end
      end

      # DELETE /#{model_plural}/1.json
      def destroy
        @#{model_singular} = #{qualified_model_classname}.find(params[:id])
        @#{model_singular}.destroy

        respond_to do |format|
          format.json { render json: nil, status: :ok }
        end
      end

      # -- end definition
    eos
    #puts "executing:"
    #puts definition
    #puts
    
    class_eval definition
  end

end