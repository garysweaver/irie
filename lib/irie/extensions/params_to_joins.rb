module Irie
  module Extensions
    # Depended on by some extensions to handle joins.
    module ParamsToJoins
      extend ::ActiveSupport::Concern
      ::Irie.available_extensions[:params_to_joins] = '::' + ParamsToJoins.name

      included do
        class_attribute(:params_to_joins, instance_writer: true) unless self.respond_to? :params_to_joins
        
        self.params_to_joins ||= {}
      end

      module ClassMethods

        protected
        
        # An alterative method to defining :through options (for can_filter_by, can_order_by, etc.)
        # in a single place that isn't on the same line as another class method.
        #
        # E.g.:
        #
        #   define_params name: {company: {employee: :full_name}},
        #                 color: :external_color
        #   can_filter_by :name
        #   default_filter_by :name, eq: 'Guest'
        #   can_order_by :color
        #   default_filter_by :color, eq: 'blue'
        def define_params(*args)
          options = args.extract_options!

          raise ::Irie::ConfigurationError.new "define_param(s) only takes a single hash of param name(s) to hash(es)" if args.length > 0

          self.params_to_joins = self.params_to_joins.deep_dup

          options.each do |param_name, through_val|
            param_name = param_name.to_s
            self.params_to_joins[param_name.to_s] = (convert = ->(hsh, orig=nil) do
              orig ||= hsh
              case hsh
              when String, Symbol
                {attr_name: hsh}
              when Hash
                case hsh.values.first
                when String, Symbol
                  {attr_name: hsh.values.first, joins: hsh.keys.first}
                when Hash
                  case hsh.values.first.values.first
                  when String, Symbol
                    attr_name = hsh.values.first.values.first
                    hsh[hsh.keys.first] = hsh.values.first.keys.first
                    {attr_name: attr_name, joins: orig}
                  when Hash
                    convert.call(hsh.values.first, orig)
                  else
                    raise ::Irie::ConfigurationError.new "Invalid :through option: #{hsh.values.first.values.first} in #{self}"
                  end
                else
                  raise ::Irie::ConfigurationError.new "Invalid :through option: #{hsh.values.first} in #{self}"
                end
              else
                raise ::Irie::ConfigurationError.new "Invalid :through option: #{hsh} in #{self}"
              end
            end)[through_val.deep_dup]
          end

          self.params_to_joins
        end
      end

      protected

      # Call .joins! on the relation with configured :through options after parsing them
      # and then return a new options hash that has :attr_name and may have :joins if
      # define_params was called or :through option was used.
      def apply_joins_and_return_relation_and_opts(relation, param_name)
        logger.debug("Irie::Extensions::ParamsToJoins.apply_joins_and_return_relation_and_opts") if Irie.debug?

        old_param_name = param_name
        opts = self.params_to_joins[param_name.to_s] || {}
        if opts[:joins]
          relation = relation.joins(opts[:joins])
          logger.debug("Irie::Extensions::ParamsToJoins.apply_joins_and_return_relation_and_opts: relation.to_sql so far: #{relation.to_sql}") if Irie.debug?
        end
        [relation, opts.reverse_merge(attr_name: param_name.to_sym)]
      end

      # Walk any configured :through options to get the ARel table or return resource_class.arel_table.
      def get_arel_table(param_name)
        opts = self.params_to_joins[param_name.to_s] || {}
        hsh = opts[:joins]
        return resource_class.arel_table unless hsh && hsh.size > 0
        # find arel_table corresponding to
        find_assoc_resource_class = ->(last_resource_class, assoc_name) do
          next_class = last_resource_class.reflections.map{|refl_assoc_name, refl| refl.class_name.constantize if refl_assoc_name.to_s == assoc_name.to_s}.compact.first
          raise ::Irie::ConfigurationError.new "#{last_resource_class} is missing association #{hsh.values.first} defined in #{self} through option or define_params" unless next_class
          next_class
        end

        (find_arel_table = ->(last_resource_class, val) do
          case val
          when String, Symbol
            find_assoc_resource_class.call(last_resource_class, val).arel_table
          when Hash
            find_arel_table.call(find_assoc_resource_class.call(last_resource_class, val.keys.first), val.values.first)
          else
            raise ::Irie::ConfigurationError.new "get_arel_table failed because unhandled #{val} in joins in through"
          end
        end)[resource_class, opts[:joins]]
      end
    end
  end
end
