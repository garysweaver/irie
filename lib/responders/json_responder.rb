# based on Jacques Fuentes (jpfuentes2) in http://stackoverflow.com/questions/9953887/simple-respond-with-in-rails-that-avoids-204-from-put/10087240#10087240
module Responders
  module JsonResponder
    protected

    # overrides actionpack/lib/action_controller/metal/responder.rb
    def api_behavior(error)
      raise error unless resourceful?

      if get?
        display resource
      elsif post?
        if RestfulJson.return_resource
          # render resource and 201
          display resource, :status => :created
        else
          display resource, :status => :created, :location => api_location
        end
      elsif RestfulJson.return_resource && put?
        # render resource and 200, instead of 204 no content
        display resource, :status => :ok
      else
        head :no_content
      end
    end
  end
end
