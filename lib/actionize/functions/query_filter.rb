# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module Actionize
  module Functions
    module QueryFilter
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        class_attribute :param_to_query, instance_writer: true
        
        self.param_to_query ||= {}

        function_for :index_filters, name: 'Actionize::Functions::Count' do
          self.param_to_query.each do |param_name, param_query|
            param_value = @aparams[param_name]
            unless param_value.nil?
              @relation = param_query.call(@relation, convert_request_param_value(param_name.to_s, param_value))
            end
          end

          nil
        end
      end

      module ClassMethods
        # Specify a custom query to filter by if the named request parameter is provided.
        #
        # t is self.model_class.arel_table and q is self.model_class.all, e.g.
        #   can_filter_by_query status: ->(t,q,param_value) { q.where(:status_code => param_value) },
        #                       color: ->(t,q,param_value) { q.where(:color => param_value) }
        def can_filter_by_query(*args)
          options = args.extract_options!

          raise "arguments #{args.inspect} are not supported by can_filter_by_query" if args.length > 0

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.param_to_query = self.param_to_query.clone
          
          options.each do |param_name, proc|
            self.param_to_query[param_name.to_sym] = proc
          end
        end
      end
    end
  end
end