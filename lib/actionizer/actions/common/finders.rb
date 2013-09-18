module Actionizer
  module Actions
    module Common
      module Finders
        extend ::ActiveSupport::Concern

        included do
          include ::Actionizer::Actions::Base
        end

        def after_find_where
          super if defined?(super)
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

          after_find_where
          @relation.send first_sym
        end
      end
    end
  end
end
