module Actionizer
  module Extensions
    # Allows use of a lambda to work with request parameters to filter results.
    module QueryFilter
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:query_filter] = '::' + QueryFilter.name

      included do
        include ::Actionizer::ParamAliases

        class_attribute(:param_to_query, instance_writer: true) unless self.respond_to? :param_to_query
        
        self.param_to_query ||= {}
      end

      module ClassMethods
        # Specify a custom query to filter by if the named request parameter is provided, e.g.
        #   can_filter_by_query status: ->(q, status) { status == 'all' ? q : q.where(:status => status) },
        #                       color: ->(q, color) { color == 'red' ? q.where("color = 'red' or color = 'ruby'") : q.where(:color => color) }
        def can_filter_by_query(*args)
          options = args.extract_options!

          raise "arguments #{args.inspect} are not supported by can_filter_by_query" if args.length > 0

          self.param_to_query = self.param_to_query.deep_dup
          
          options.each do |param_name, proc|
            self.param_to_query[param_name.to_sym] = proc
          end
        end
      end

      def index_filters
        self.param_to_query.each do |param_name, param_query|
          param_value = params_for_index[param_name]
          unless param_value.nil?
            @relation = param_query.call(@relation, convert_param_value(param_name.to_s, param_value))
          end
        end

        super if defined?(super)
      end
    end
  end
end
