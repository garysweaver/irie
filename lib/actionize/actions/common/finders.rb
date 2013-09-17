module Actionize
  module Actions
    module Common
      module Finders
        extend ::ActiveSupport::Concern

        include ::Actionize::ExecutesFunctions
        include ::Actionize::RegistersFunctions

        included do
          function_group :after_find_where
        end

        # Finds model using provided info in provided allowed params,
        # via where(...).first.
        #
        # Supports composite_keys.
        def find_model_instance(aparams)
          find_model_instance_with aparams, :first
        end

        # Finds model using provided info in provided allowed params,
        # via where(...).first! (raise exception if not found).
        #
        # Supports composite_keys.
        def find_model_instance!(aparams)
          find_model_instance_with aparams, :first!
        end

      private

        def find_model_instance_with(aparams, first_sym)
          # primary_key array support for composite_primary_keys.
          @relation = @model_class
          if @model_class.primary_key.is_a? Array
            @relation.primary_key.each do |pkey|
              @relation = @relation.where(pkey.to_sym => convert_param_value(pkey.to_s, aparams[pkey])) if aparams.key?(pkey)
            end
          else
            id_param_name = (self.id_is_primary_key_param && aparams.key?(:id)) ? 'id' : @model_class.primary_key.to_s
            @relation = @relation.where(@model_class.primary_key.to_sym => convert_param_value(id_param_name, aparams[id_param_name]))
          end

          short_circuit_result = execute_functions(:after_find_where)
          return short_circuit_result if short_circuit_result
          @relation.send first_sym
        end
      end
    end
  end
end
