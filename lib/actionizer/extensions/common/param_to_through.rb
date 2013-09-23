# Depended on by some extensions to handle joins.
module Actionizer
  module Extensions
    module Common
      module ParamToThrough
        extend ::ActiveSupport::Concern

        included do
          class_attribute(:param_to_through, instance_writer: true) unless self.respond_to? :param_to_through
          
          self.param_to_through ||= {}
        end

        def index_filters
          self.param_to_through.each do |param_name, through_array|
            param_value = params_for_index[param_name]
            unless param_value.nil?
              # build query
              # e.g. SomeModel.all.joins({:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}).where(sub_sub_sub_assoc_model_table_name: {column_name: value})
              last_model_class = @model_class
              joins = nil # {:assoc_name => {:sub_assoc => {:sub_sub_assoc => :sub_sub_sub_assoc}}
              through_array.each do |association_or_attribute|
                if association_or_attribute == through_array.last
                  # must convert param value to string before possibly using with ARel because of CVE-2013-1854, fixed in: 3.2.13 and 3.1.12 
                  # https://groups.google.com/forum/?fromgroups=#!msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ
                  @relation.joins!(joins).where!(last_model_class.table_name.to_sym => {association_or_attribute => convert_param_value(param_name.to_s, param_value)})
                else
                  found_classes = last_model_class.reflections.collect {|association_name, reflection| reflection.class_name.constantize if association_name.to_sym == association_or_attribute}.compact
                  if found_classes.size > 0
                    last_model_class = found_classes[0]
                  else
                    # bad can_filter_by :through found at runtime
                    raise "#{association_or_attribute.inspect} not found on #{last_model_class}"
                  end

                  if joins.nil?
                    joins = association_or_attribute
                  else
                    joins = {association_or_attribute => joins}
                  end
                end
              end
            end
          end

          super if defined?(super)
        end
      end
    end
  end
end
