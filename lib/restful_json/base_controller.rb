module RestfulJson
  module BaseController
    extend ::ActiveSupport::Concern

    module ClassMethods
      # <b>DEPRECATED:</b> Please use <tt>include RestfulJson::DefaultController</tt> instead.
      def acts_as_restful_json
        warn "[DEPRECATION] `acts_as_restful_json` is deprecated. Please use `include RestfulJson::DefaultController` or see documentation."
        include ::RestfulJson::DefaultController
      end
    end
  end
end
