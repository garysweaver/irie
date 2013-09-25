module Actionizer
  module Actions
    module Show
      extend ::ActiveSupport::Concern

      ::Actionizer.available_actions[:show] = '::' + Show.name

      included do
        include ::Actionizer::Actions::Base
        include ::Actionizer::Actions::Common::Finders

        Array.wrap(self.autoincludes[:show]).each do |obj|
          case obj
          when Symbol
            begin
              include self.available_extensions[obj.to_sym].constantize
            rescue NameError => e
              raise "Could not resolve extension module '#{self.available_extensions[obj.to_sym]}' for key for #{obj.to_sym.inspect}. Check Actionizer/self.available_extensions[#{obj.to_sym.inspect}].constantize. Error: \n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          when String
            begin
              include obj.constantize
            rescue NameError => e
              raise "Could not resolve extension module: #{obj}. Error: \n#{e.message}\n\n#{e.backtrace.join("\n")}"
            end
          else
            include obj
          end
        end
      end

      # The controller's show (get) method to return a resource.
      def show
        return catch(:action_break) do
          render_show perform_show(params_for_show)
        end || @action_result
      end

      def perform_show(the_params)
        record = find_model_instance!(the_params)
        instance_variable_set(@model_at_singular_name_sym, record)
      end

      def params_for_show
        params
      end

      def render_show(record)
        perform_render(record)
      end
    end
  end
end
