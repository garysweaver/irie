module Actionize
  module Functions
    module Order
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions
      include ::Actionize::Functions::Common::ParamToThrough

      included do
        class_attribute :can_be_ordered_by, instance_writer: true
        class_attribute :default_ordered_by, instance_writer: true
        
        self.can_be_ordered_by ||= []
        self.default_ordered_by ||= {}

        function_for :after_index_filters, name: 'Actionize::Functions::Count' do
          already_ordered_by = []
          __send__(:aliased_params, :order).each do |param_value|
            order_params = param_value.split(self.filter_split)
            order_params.each do |order_param_value|
              # not using convert_param_value here.
              # (these should be attribute names, not attribute values.)

              # remove optional preceding - or + to act as directional
              direction = :asc
              if order_param_value[0] == '-'
                direction = :desc
                order_param_value = order_param_value.reverse.chomp('-').reverse
              elsif order_param_value[0] == '+'
                order_param_value = order_param_value.reverse.chomp('+').reverse
              end
              # order of logic here is important:
              # do not to_sym the partial param value until passes whitelist to avoid symbol attack
              if self.can_be_ordered_by.include?(order_param_value) && !already_ordered_by.include?(order_param_value.to_sym)                
                @relation.order!(order_param_value.to_sym => direction)
                already_ordered_by << order_param_value.to_sym
              end
            end
          end

          self.default_ordered_by.each do |attr_sym, direction|
            if !already_ordered_by.include?(attr_sym)
              @relation.order!(attr_sym => direction)
              already_ordered_by << attr_sym
            end
          end

          nil
        end
      end

      module ClassMethods
        # A whitelist of orderable attributes.
        #
        # If no options are provided or the :using option is provided, defines attributes that are orderable through the operation(s) already defined in can_filter_by_default_using, or can specify attributes:
        #   can_order_by :attr_name_1, :attr_name_2
        # So that you could call: http://.../foobars?order=attr_name_1,-attr_name_2
        # to order by attr_name_1 asc then attr_name_2 desc.
        #
        # When :through is specified, it will take the array supplied to through as 0 to many model names following by an attribute name. It will follow through
        # each association until it gets to the attribute to filter by that via ARel joins, e.g. if the model Foobar has an association to :foo, and on the Foo model there is an assocation
        # to :bar, and you want to order by bar.name (foobar.foo.bar.name):
        #  can_order_by :my_param_name, through: [:foo, :bar, :name]
        def can_order_by(*args)
          options = args.extract_options!

          opt_through = options.delete(:through)
          raise "options #{options.inspect} not supported by can_order_by" if options.present?

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.can_be_ordered_by = self.can_be_ordered_by.clone

          args.each do |arg|
            # store as strings because we have to do a string comparison later to avoid req param symbol attack
            self.can_be_ordered_by << arg.to_s unless self.can_be_ordered_by.include?(arg.to_s)
          end

          # This does the same as the through in can_filter_by: it just sets up joins in the index action.
          if opt_through
            # Shallow clone to help avoid subclass inheritance related sharing issues.
            self.param_to_through = self.param_to_through.clone

            args.each do |through_key|
              self.param_to_through[through_key.to_sym] = opt_through
            end
          end
        end

        # Takes an string, symbol, array, hash to indicate order. If not a hash, assumes is ascending. Is cumulative and order defines order of sorting, e.g:
        #   #would order by foo_color attribute ascending
        #   default_order_by :foo_color
        # or
        #   default_order_by foo_date: :asc, bar_date: :desc
        # or you could be completely insane and do:
        #   default_order_by {foo_date: :asc}, :foo_color, 'foo_name', another_date: :asc, bar_date: :desc
        def default_order_by(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.default_ordered_by = self.default_ordered_by.clone

          # hash is ordered in recent versions of Ruby we support
          args.flatten.each do |item|
            case item
            when Hash
              self.default_ordered_by.merge!(item)
            when String, Symbol
              self.default_ordered_by[item.to_sym] = :asc
            else
              raise "Can't default_order_by #{item}"
            end
          end
          self.default_ordered_by.merge!(options)
        end
      end
    end
  end
end

        