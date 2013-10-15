module Actionizer
  module Extensions
    # Allows ability to do `.includes(...)` on query to avoid n+1 queries.
    module QueryIncludes
      extend ::ActiveSupport::Concern
      ::Actionizer.available_extensions[:query_includes] = '::' + QueryIncludes.name

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

          self.all_action_query_includes = self.all_action_query_includes.deep_dup
          old_options = self.all_action_query_includes.extract_options!
          self.all_action_query_includes = (self.all_action_query_includes + args).uniq
          self.all_action_query_includes << old_options.merge(options)
        end

        # Calls .includes(...) only on specified action queries, e.g.:
        #   query_includes_for :create, :update, are: [:category, :comments]
        #   query_includes_for :index, are: [posts: [{comments: :guest}, :tags]]
        def query_includes_for(*args)
          options = args.extract_options!

          opt_are = options.delete(:are)
          raise "options #{options.inspect} not supported by can_filter_by" if options.present?

          self.action_to_query_includes = self.action_to_query_includes.deep_dup

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
        logger.debug("Actionizer::Extensions::QueryIncludes.after_index_filters") if Actionizer.debug?
        apply_includes
        super if defined?(super)
      end

      def after_find_where
        logger.debug("Actionizer::Extensions::QueryIncludes.after_find_where") if Actionizer.debug?
        apply_includes
        super if defined?(super)
      end

      def apply_includes
        logger.debug("Actionizer::Extensions::QueryIncludes.apply_includes") if Actionizer.debug?
        this_includes = self.action_to_query_includes[params[:action].to_sym] || self.all_action_query_includes
        if this_includes && this_includes.size > 0
          @relation.includes!(*this_includes)
        end
      end
    end
  end
end
