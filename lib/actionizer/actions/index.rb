module Actionizer
  module Actions
    module Index
      extend ::ActiveSupport::Concern
      
      ::Actionizer.available_actions[:index] = '::' + Index.name

      included do
        include ::Actionizer::Actions::Base

        Array.wrap(self.autoincludes[:index]).each do |obj|
          case obj
          when Symbol
            begin
              include self.available_extensions[obj.to_sym].constantize
            rescue NameError => e
              raise ::Actionizer::ConfigurationError.new "Could not resolve extension module '#{self.available_extensions[obj.to_sym]}' for key for #{obj.to_sym.inspect}. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          when String
            begin
              include obj.constantize
            rescue NameError => e
              raise ::Actionizer::ConfigurationError.new "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
            end
          else
            include obj
          end
        end
      end

      def index_filters
        logger.debug("Actionizer::Actions::Index.index_filters") if Actionizer.debug?
        super if defined?(super)
      end

      def after_index_filters
        logger.debug("Actionizer::Actions::Index.after_index_filters") if Actionizer.debug?
        super if defined?(super)
      end

      # The controller's index (list) method to list resources.
      def index
        logger.debug("Actionizer::Actions::Index.index") if Actionizer.debug?
        return catch(:action_break) do
          render_index perform_index(params_for_index)
        end || @action_result
      end

      def query_for_index
        logger.debug("Actionizer::Actions::Index.query_for_index") if Actionizer.debug?
        @relation = resource_class.all
      end

      def params_for_index
        logger.debug("Actionizer::Actions::Index.params_for_index") if Actionizer.debug?
        params
      end

      def perform_index(the_params)
        logger.debug("Actionizer::Actions::Index.perform_index(#{the_params.inspect})") if Actionizer.debug?
        @relation = query_for_index
        index_filters
        after_index_filters
        instance_variable_set(collection_variable_name_sym, @relation.to_a)
      end

      def render_index(records)
        logger.debug("Actionizer::Actions::Index.render_index(#{records.inspect})") if Actionizer.debug?
        perform_render(records, options_for_collection_render(records))
      end

      def options_for_collection_render(records)
        logger.debug("Actionizer::Actions::Index.options_for_collection_render(#{records.inspect})") if Actionizer.debug?
        options_for_render(records)
      end
    end
  end
end
