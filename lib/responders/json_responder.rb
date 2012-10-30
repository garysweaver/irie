require 'responders'

# from Jacques Fuentes (jpfuentes2) in http://stackoverflow.com/questions/9953887/simple-respond-with-in-rails-that-avoids-204-from-put/10087240#10087240
module Responders
  module JsonResponder
    protected
    
    def api_behavior(error)
      if !RestfulJson.return_resource
        super
      elsif post?
        # render resource and 201
        display resource, :status => :created
      elsif put?
        # render resource and 200, instead of 204 no content
        display resource, :status => :ok
      else
        super
      end
    end
  end
end
