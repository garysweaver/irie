module RestfulJson
  module Roar
    class CollectionlessAutorepresenter
      include Roar::Representer::JSON

      def self.autoconfigure(model_class)
        association_name_sym_to_association = {}
        model_class.reflect_on_all_associations do |association|
          association_name_sym_to_association[association.name.to_sym] = association
        end

        model_class._accessible_attributes[:default].each do |attr|
          attr_sym = attr.to_sym
          property attr_sym unless association_name_sym_to_association[attr_sym] 
        end
      end
    end
  end
end
