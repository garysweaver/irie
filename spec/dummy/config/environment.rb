# Load the rails application.
require File.expand_path('../application', __FILE__)

# Initialize the rails application.
Dummy::Application.initialize!

ActiveRecord::Base.send(:include, CanCan::ModelAdditions)
ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)
