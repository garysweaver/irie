class RestfulJson::Roar::Autorepresenter
  include Roar::Representer::JSON

  def self.autoconfigure(model_class)
    association_name_sym_to_association = {}
    model_class.reflect_on_all_associations do |association|
      association_name_sym_to_association[association.name.to_sym] = association
    end

    model_class._accessible_attributes[:default].do each |attr|
      attr_sym = attr.to_sym
      property attr_sym unless association_name_sym_to_association[attr_sym] 
    end

    # will this work? may need self._collected_accepts_nested_attributes_for from restful_json model to determine if associations are writeable.
    association_name_sym_to_association.keys.sort.each do |association_name_sym|
      association = association_name_sym_to_association[association_name_sym]
      # TODO: if we want to use a different rep for many vs one, use if [:has_many, :has_and_belongs_to_many].include?(association.macro)
      collection association_name_sym, :class => association.class_name, :extend => RestfulJson::Roar::CollectionlessAutorepresenter
    end
  end
end
