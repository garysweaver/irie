module Actionizer
  module Extensions
    module Common
      # Depended on by some extensions to handle joins.
      module ParamToThrough
        extend ::ActiveSupport::Concern

        included do
          class_attribute(:param_to_through, instance_writer: true) unless self.respond_to? :param_to_through
          
          self.param_to_through ||= {}
        end

        module ClassMethods
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

            raise "define_param(s) only takes a single hash of param name(s) to hash(es)" if args.length > 0

            self.param_to_through = self.param_to_through.deep_dup

            options.each do |param_name, through_val|
              param_name = param_name.to_s
              self.param_to_through[param_name] = (convert = ->(hsh, orig=nil) do
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
                      raise "Invalid :through option: #{hsh.values.first.values.first} in #{self}"
                    end
                  else
                    raise "Invalid :through option: #{hsh.values.first} in #{self}"
                  end
                else
                  raise "Invalid :through option: #{hsh} in #{self}"
                end
              end)[through_val.deep_dup]
            end

            self.param_to_through
          end
          alias define_param define_params
        end

        # Call .joins! on the relation with configured :through options after parsing them
        # and then return a new options hash that has :attr_name and may have :joins if
        # define_params was called or :through option was used.
        def apply_joins_and_return_opts(param_name)
          old_param_name = param_name
          opts = self.param_to_through[param_name.to_s] || {}
          @relation.joins!(opts[:joins]) if opts[:joins]
          opts.reverse_merge(attr_name: param_name.to_sym)
        end

        # Walk any configured :through options to get the ARel table or return resource_class.arel_table.
        def get_arel_table(param_name)
          opts = self.param_to_through[param_name.to_s] || {}
          hsh = opts[:joins]
          return resource_class.arel_table unless hsh && hsh.size > 0
          # find arel_table corresponding to
          find_assoc_resource_class = ->(last_resource_class, assoc_name) do
            next_class = last_resource_class.reflections.map{|refl_assoc_name, refl| refl.class_name.constantize if refl_assoc_name.to_s == assoc_name.to_s}.compact.first
            raise "#{last_resource_class} is missing association #{hsh.values.first} defined in #{self} through option or define_params" unless next_class
            next_class
          end

          (find_arel_table = ->(last_resource_class, val) do
            case val
            when String, Symbol
              find_assoc_resource_class.call(last_resource_class, val).arel_table
            when Hash
              find_arel_table.call(find_assoc_resource_class.call(last_resource_class, val.keys.first), val.values.first)
            else
              raise "get_arel_table failed because unhandled #{val} in joins in through"
            end
          end)[resource_class, opts[:joins]]
        end
      end
    end
  end
end
