# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module Actionizer
  module Extensions
    module CustomQuery
      extend ::ActiveSupport::Concern

      included do
        include ::Actionizer::FunctionParamAliasing

        class_attribute :action_to_query, instance_writer: true

        self.action_to_query ||= {}
      end

      module ClassMethods
        # Specify a custom query. If action specified does not have a method, it will alias_method index to create a new action method with that query.
        #
        # t is self.model_class.arel_table and q is self.model_class.all, e.g.
        #   query_for index: ->(t,q) { q.where(:status_code => 'green') },
        #             at_risk: ->(t,q) { q.where(:status_code => 'yellow') }
        def query_for(*args)
          options = args.extract_options!

          raise "arguments #{args.inspect} are not supported by query_for" if args.length > 0

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.action_to_query = self.action_to_query.clone
          
          options.each do |action_name, proc|
            self.action_to_query[action_name.to_sym] = proc
            
            unless action_name.to_sym == :index
              alias_index_methods action_name
            end
          end
        end

        def alias_index_methods(action_name)
          self.instance_methods.collect{|m|m.to_s}.each do |method_name|
            alias_method(method_name.to_s.gsub('index', action_name.to_s).to_sym, method_name.to_sym) if method_name == 'index' || method_name['_index'] || method_name['index_']
          end
        end
      end

      def query_for_index
        custom_query = self.action_to_query[params[:action].to_sym]
        @relation = custom_query ? custom_query.call(super) : super
      end
    end
  end
end
