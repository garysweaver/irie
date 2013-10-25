## Tommy's hack to disable implicit JSON serialization so we can ensure jbuilder view is getting used
#::ActionController::Renderers.add :json do |json, options|
#  if json.kind_of?(Hash)
#    json = json.to_json(options)
#  elsif !json.kind_of?(String)
#    raise "No view defined for json action. json= #{json.inspect}, options = #{options.inspect}"
#  end
#
#  self.content_type ||= Mime::JSON
#  json
#end
#