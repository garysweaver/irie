module Actionizer
  module Actions
    module New
      extend ::ActiveSupport::Concern

      ::Actionizer.available_actions[:new] = '::' + New.name

      included do
        include ::Actionizer::Actions::Base

        Array.wrap(self.autoincludes[:new]).each do |obj|
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

      # The controller's new method (e.g. used for new record in html format).
      def new
        return catch(:action_break) do
          render_new perform_new(params_for_new)
        end || @action_result
      end

      def params_for_new
        params
      end

      def perform_new(the_params)
        instance_variable_set(@model_at_singular_name_sym, @model_class.new)
      end

      def render_new(record)
        perform_render(record)
      end
    end
  end
end
