# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Dummy::Application.initialize!

RestfulJson.configure do
  self.can_filter_by_default_using = [:eq]
  self.debug = true
  self.filter_split = ','
  self.formats = :json
  self.number_of_records_in_a_page = 15
  self.predicate_prefix = '!'
  self.return_resource = true
  self.render_enabled = true
  self.use_permitters = true
end
