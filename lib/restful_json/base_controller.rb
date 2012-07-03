class RestfulJson::BaseController < ApplicationController

  def index
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.all
    instance_variable_set("@#{@__restful_json_model_plural}".to_sym, value)
    respond_to do |format|
      format.json { render json: {@__restful_json_model_plural.to_sym => value} }
    end
  end

  def show
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.find(params[:id])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      format.json { render json: {@__restful_json_model_singular.to_sym => value} }
    end
  end

  # POST /#{model_plural}.json
  def create
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.new(params[@__restful_json_model_singular.to_sym])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      if @__restful_json_model_singular.save
        format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :created, location: value }
      else
        format.json { render json: value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /#{model_plural}/1.json
  def update
    return if restful_json_controller_not_yet_configured?
    value = @__restful_json_class.find(params[:id])
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, value)
    respond_to do |format|
      if @__restful_json_model_singular.save
        format.json { render json: {@__restful_json_model_singular.to_sym => value}, status: :ok }
      else
        format.json { render json: value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /#{model_plural}/1.json
  def destroy
    return if restful_json_controller_not_yet_configured?
    @__restful_json_model_singular = @__restful_json_class.find(params[:id])
    @__restful_json_model_singular.destroy
    respond_to do |format|
      format.json { render json: nil, status: :ok }
    end
  end

  # note: model_class can be fully-qualified like MyModule::MySubModule::MyClass
  def self.restful_json_model(model_class)
    #puts "Configuring #{self.name} with RESTful JSON services for #{model_class.inspect}"

    # is_a? doesn't work with classes 
    raise "restful_json_model must be called with a model class that extends ActiveRecord::Base" unless model_class.ancestors.include?(ActiveRecord::Base)
    # this works whether or not the class is in a defined module
    unqualified_model_classname = model_class.name.split("::").last.underscore
    @__restful_json_model_singular = unqualified_model_classname
    @__restful_json_model_plural = unqualified_model_classname.pluralize
    @__restful_json_class = model_class
    instance_variable_set("@#{@__restful_json_model_plural}".to_sym, nil)
    instance_variable_set("@#{@__restful_json_model_singular}".to_sym, nil)
    puts "'#{self.name}' using model class: '#{@__restful_json_class}', attributes: '@#{@__restful_json_model_plural}', '@#{@__restful_json_model_singular}'"
  end

private

  attr_accessor :__restful_json_class, :__restful_json_model_plural, :__restful_json_model_singular

  # Stub out actions until dynamically implemented, otherwise will get something like:
  # AbstractController::ActionNotFound (The action 'index' could not be found for SomeModelController):

  # This borrows heavily from Dan Gebhardt's example at: https://github.com/dgeb/ember_data_example/blob/master/app/controllers/contacts_controller.rb
  def restful_json_controller_not_yet_configured?
    if @__restful_json_class == nil || @__restful_json_model_plural == nil || @__restful_json_model_singular == nil
      puts "RestfulJson controller #{self} called before setup, so returning 503 error."
      respond_to do |format|
        format.json { render json: value.errors, status: :service_unavailable }
      end
    end
  end
end