class RestfulJson::Controller < RestfulJson::BaseController

  # attempt to autodetermine the model name from the name to avoid potentially dangerous copy/paste issues if using restful_json_model method directly.
  def initialize
    super
    puts "Attempting to autoconfigure RESTful JSON services for #{self.class.name}"
    fully_qualified_restful_json_model_name = self.class.name.chomp('Controller')
    unqualified_restful_json_model_name = fully_qualified_restful_json_model_name.split("::").last
    if is_activerecord_model?(fully_qualified_restful_json_model_name)
      #restful_json_model fully_qualified_restful_json_model_name.constantize
      # This must be run when the class is instantiated, so we'll do the equivalent of having just written this line into the code of the class.
      class_eval "restful_json_model #{fully_qualified_restful_json_model_name.constantize.name}"
    elsif fully_qualified_restful_json_model_name != unqualified_restful_json_model_name && is_activerecord_model?(unqualified_restful_json_model_name)      
      #restful_json_model unqualified_restful_json_model_name.constantize
      # This must be run when the class is instantiated, so we'll do the equivalent of having just written this line into the code of the class.
      class_eval "restful_json_model #{unqualified_restful_json_model_name.constantize.name}"
    else
      if fully_qualified_restful_json_model_name != unqualified_restful_json_model_name
        puts "Could not autodetermine restful json model for #{controller_name} (neither #{fully_qualified_restful_json_model_name} or #{unqualified_restful_json_model_name} were available models that extended ActiveRecord::Base). You will need to define 'restful_json_model FullyQualifiedClassName'."
      else
        puts "Could not autodetermine restful json model for controller #{controller_name} (#{fully_qualified_restful_json_model_name} was not an available model that extended ActiveRecord::Base). Assuming a restful_json_model ModelName (where ModelName should be fully-qualified) will define the model class, although using convention ModelNameController convention is suggested."
      end
    end
  end

private

  def is_activerecord_model?(model_classname_candidate)
    begin
      model_class = model_classname_candidate.constantize
      # is_a? doesn't work with classes
      if model_class.ancestors.include?(ActiveRecord::Base)
        puts "#{model_classname_candidate} is a valid class and inherits from ActiveRecord::Base."
        return true
      else
        puts "#{model_classname_candidate} is a valid class but does not inherit from ActiveRecord::Base."
      end
    rescue NameError => e
      # TODO: this is also catching issue where constantize is not defined on String via ActiveSupport Inflector and gives misleading error, so printing it out for now.
      puts "#{model_classname_candidate} was not a class. Error: #{e.message} #{e.backtrace}"
    end
    return false
  end

end