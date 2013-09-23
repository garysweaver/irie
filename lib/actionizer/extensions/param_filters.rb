# Before every controller action, calls authorize! with the action and model class
# for easy integration with authorizers like CanCan, etc.
module Actionizer
  module Extensions
    module ParamFilters
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:param_filters] = '::' + ParamFilters.name

      included do
        include ::Actionizer::ParamAliases
        include ::Actionizer::Extensions::Common::ParamToThrough

        class_attribute(:default_filtered_by, instance_writer: true) unless self.respond_to? :default_filtered_by
        class_attribute(:param_to_attr_and_arel_predicate, instance_writer: true) unless self.respond_to? :param_to_attr_and_arel_predicate

        self.default_filtered_by ||= {}
        self.param_to_attr_and_arel_predicate ||= {}
      end

      module ClassMethods
        # A whitelist of filters and definition of filter options related to request parameters.
        #
        # If no options are provided or the :using option is provided, defines attributes that are queryable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
        #   can_filter_by :attr_name_1, :attr_name_2 # implied using: [eq] if RestfulJson.can_filter_by_default_using = [:eq] 
        #   can_filter_by :attr_name_1, :attr_name_2, using: [:eq, :not_eq]
        #
        # When :through is specified, it will take the array supplied to through as 0 to many model names following by an attribute name. It will follow through
        # each association until it gets to the attribute to filter by that via ARel joins, e.g. if the model Foobar has an association to :foo, and on the Foo model there is an assocation
        # to :bar, and you want to filter by bar.name (foobar.foo.bar.name):
        #  can_filter_by :my_param_name, through: [:foo, :bar, :name]
        def can_filter_by(*args)
          options = args.extract_options!

          opt_using = options.delete(:using)
          opt_through = options.delete(:through)
          raise "options #{options.inspect} not supported by can_filter_by" if options.present?

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.param_to_attr_and_arel_predicate = self.param_to_attr_and_arel_predicate.clone

          # :using is the default action if no options are present
          if opt_using || options.size == 0
            predicates = Array.wrap(opt_using || self.can_filter_by_default_using)
            predicates.each do |predicate|
              predicate_sym = predicate.to_sym
              args.each do |attr_name|
                attr_sym = attr_name.to_sym
                self.param_to_attr_and_arel_predicate[attr_sym] = [attr_sym, :eq] if predicate_sym == :eq
                self.param_to_attr_and_arel_predicate["#{attr_name}#{self.predicate_prefix}#{predicate}".to_sym] = [attr_sym, predicate_sym]
              end
            end
          end

          if opt_through
            args.each do |through_key|
              # Shallow clone to help avoid subclass inheritance related sharing issues.
              self.param_to_through = self.param_to_through.clone

              # can override another through defined elsewhere
              self.param_to_through[through_key.to_sym] = opt_through
            end
          end
        end

        # Specify default filters and predicates to use if no filter is provided by the client with
        # the same param name, e.g. if you have:
        #   default_filter_by :attr_name_1, eq: 5
        #   default_filter_by :production_date, :creation_date, gt: 1.year.ago, lteq: 1.year.from_now
        # and both attr_name_1 and production_date are supplied by the client, then it would filter
        # by the client's attr_name_1 and production_date and filter creation_date by
        # both > 1 year ago and <= 1 year from now.
        def default_filter_by(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.default_filtered_by = self.default_filtered_by.clone
          
          args.each do |attr_name|
            if self.default_filtered_by[attr_name.to_sym]
              # have merge create new instance to help avoid subclass inheritance related sharing issues.
              self.default_filtered_by[attr_name.to_sym] = self.default_filtered_by[attr_name.to_sym].merge(options)
            else
              self.default_filtered_by[attr_name.to_sym] = options
            end
          end
        end
      end

      def index_filters
        filtered_by_param_names = []
        self.param_to_attr_and_arel_predicate.keys.each do |param_name|
          if param_to_attr_and_arel_predicate[param_name]
            attr_sym = param_to_attr_and_arel_predicate[param_name][0]
            predicate_sym = param_to_attr_and_arel_predicate[param_name][1]
            if params_for_index.key?(param_name)
              one_or_more_param = params_for_index[param_name].to_s.split(self.filter_split).collect{|v| convert_param_value(attr_sym.to_s, v)}
              @relation.where!(
                @relation.arel_table[attr_sym].
                try(predicate_sym, 
                  one_or_more_param))
              filtered_by_param_names << attr_sym
            end
          end
        end

        self.default_filtered_by.each do |attr_sym, predicates_to_default_values|
          unless filtered_by_param_names.include?(attr_sym) || predicates_to_default_values.blank?
            predicates_to_default_values.each do |predicate_sym, one_or_more_default_value|
              @relation.where!(t[attr_sym].try(predicate_sym, Array.wrap(one_or_more_default_value)))
            end
          end
        end
        
        super if defined?(super)
      end

    end
  end
end
