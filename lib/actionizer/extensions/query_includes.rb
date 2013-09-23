module Actionizer
  module Extensions
    module QueryIncludes
      extend ::ActiveSupport::Concern
      Actionizer.available_extensions[:query_includes] = '::' + QueryIncludes.name

      included do
        include ::Actionizer::ParamAliases

        class_attribute(:action_to_query_includes, instance_writer: true) unless self.respond_to? :action_to_query_includes
        class_attribute(:all_action_query_includes, instance_writer: true) unless self.respond_to? :all_action_query_includes

        self.action_to_query_includes ||= {}
        self.all_action_query_includes ||= []
      end

      module ClassMethods
        # Calls .includes(*args) on all action queries with args provided to query_includes, e.g.:
        #   query_includes :category, :comments
        # or:
        #   query_includes posts: [{comments: :guest}, :tags]
        # Note that query_includes_for overrides includes specified by query_includes.
        def query_includes(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.all_action_query_includes = self.all_action_query_includes.clone

          options.merge!(self.all_action_query_includes.extract_options!)
          self.all_action_query_includes += args
          self.all_action_query_includes << options
        end

        # Calls .includes(...) only on specified action queries, e.g.:
        #   query_includes_for :create, :update, are: [:category, :comments]
        #   query_includes_for :index, are: [posts: [{comments: :guest}, :tags]]
        def query_includes_for(*args)
          options = args.extract_options!

          opt_are = options.delete(:are)
          raise "options #{options.inspect} not supported by can_filter_by" if options.present?

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.action_to_query_includes = self.action_to_query_includes.clone

          args.each do |an_action|
            if opt_are
              (self.action_to_query_includes ||= {}).merge!({an_action.to_sym => opt_are})
            else
              raise "#{self.class.name} must supply an :are option with includes_for #{an_action.inspect}"
            end
          end
        end
      end

      def after_index_filters
        apply_includes
        super if defined?(super)
      end

      def after_find_where
        apply_includes
        super if defined?(super)
      end

      def apply_includes
        this_includes = self.action_to_query_includes[params[:action].to_sym] || self.all_action_query_includes
        if this_includes && this_includes.size > 0
          @relation.includes!(*this_includes)
        end
      end
    end
  end
end
