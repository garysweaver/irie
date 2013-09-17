module Actionize
  module Functions
    module QueryIncludes
      extend ::ActiveSupport::Concern

      include ::Actionize::FunctionParamAliasing
      include ::Actionize::RegistersFunctions

      included do
        class_attribute :action_to_query_includes, instance_writer: true
        class_attribute :all_action_query_includes, instance_writer: true

        self.action_to_query_includes ||= {}
        self.all_action_query_includes ||= []
        
        function_for :after_index_filters, :after_find_where, name: 'Actionize::Functions::QueryIncludes' do
          this_includes = self.action_to_query_includes[@aparams[:action].to_sym] || self.query_includes
          if this_includes && this_includes.size > 0
            @relation.includes!(*this_includes)
          end
        end
      end

      module ClassMethods
        # Calls .includes(...) on all action queries, e.g.:
        #   query_includes :category, :comments
        # or .includes({posts: [{comments: :guest}, :tags]}):
        #   query_includes posts: [{comments: :guest}, :tags]
        # if query_includes_for overrides includes specified by query_includes per action.
        def query_includes(*args)
          options = args.extract_options!

          # Shallow clone to help avoid subclass inheritance related sharing issues.
          self.all_action_query_includes = self.all_action_query_includes.clone

          options.merge!(self.all_action_query_includes.extract_options!)
          self.all_action_query_includes += args
          self.all_action_query_includes << options
        end

        # Calls .includes(...) only on specified action queries, e.g.:
        #   query_includes_for :create, are: [:category, :comments]
        #   query_includes_for :index, :a_custom_action, are: [posts: [{comments: :guest}, :tags]]
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

      #def current_action_includes
      #  self.action_to_query_includes[params[:action].to_sym] || self.query_includes
      #end
    end
  end
end
