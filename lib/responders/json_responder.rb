# from Jacques Fuentes (jpfuentes2) in http://stackoverflow.com/questions/9953887/simple-respond-with-in-rails-that-avoids-204-from-put/10087240#10087240
module Responders::JsonResponder
  protected

  # simply render the resource even on POST instead of redirecting for ajax
  def api_behavior(error)
    if post?
      display resource, :status => :created
    # render resource instead of 204 no content
    elsif put?
      display resource, :status => :ok
    else
      super
    end
  end
end
