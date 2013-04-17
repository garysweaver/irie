module RestfulJson
  CONTROLLER_OPTIONS = [
    :can_filter_by_default_using, 
    :debug,
    :filter_split,
    :formats,
    :number_of_records_in_a_page,
    :predicate_prefix,
    :return_resource,
    :render_enabled,
    :use_permitters,
    :avoid_respond_with,
    :return_error_data,
    :rescue_class,
    :rescue_handlers
  ]
  
  class << self
    CONTROLLER_OPTIONS.each{|o|attr_accessor o}
    alias_method :debug?, :debug
    def configure(&blk); class_eval(&blk); end
  end
end

RestfulJson.configure do
  self.can_filter_by_default_using = [:eq]
  self.debug = false
  self.filter_split = ','.freeze
  self.formats = :json, :html
  self.number_of_records_in_a_page = 15
  self.predicate_prefix = '!'.freeze
  self.return_resource = false
  self.render_enabled = true
  self.use_permitters = true
  self.avoid_respond_with = true
  self.return_error_data = true
  # Set to nil to reraise StandardError in rescue vs. calling render_error(e) to render using restful_json
  self.rescue_class = StandardError
  # Ordered array of handlers to handle rescue of self.rescue_class or sub types. Can use optional i18n_key for message, but will default to e.message if not found.
  # Eventually may support [DataMapper::ObjectNotFoundError], [MongoMapper::DocumentNotFound], etc.
  # If no exception_classes or exception_ancestor_classes provided, it will always match self.rescue_class.
  self.rescue_handlers = [
    {exception_classes: [ActiveRecord::RecordNotFound], status: :not_found, i18n_key: 'api.not_found'.freeze},
    {status: :internal_server_error, i18n_key: 'api.internal_server_error'.freeze}
  ]
end
