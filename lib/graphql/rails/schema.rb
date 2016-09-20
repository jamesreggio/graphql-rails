module GraphQL
  module Rails
    # Defines the GraphQL schema, consisting of
    # queries, mutations, and subscriptions.
    module Schema
      extend self

      # Clear internal state, probably due to a Rails reload.
      def clear
        @schema = nil
        @fields = Hash.new { |hash, key| hash[key] = [] }
      end

      TYPES = [:query, :mutation, :subscription]

      # Register a field in the GraphQL schema.
      TYPES.each do |type|
        define_method "add_#{type.to_s}" do |field|
          @schema = nil # Invalidate cached schema.
          @fields[type].push field
        end
      end

      # Lazily build the GraphQL schema instance.
      def instance
        @schema ||= GraphQL::Schema.new begin
          TYPES.reduce({
            max_depth: Rails.config.max_depth,
            types: Types.explicit,
          }) do |schema, type|
            fields = @fields[type]
            unless fields.empty?
              # Build an object for each operation type.
              schema[type] = GraphQL::ObjectType.define do
                name type.to_s.capitalize
                description "Root #{type.to_s} for this schema"
                # Add a field for each operation.
                fields.each do |value|
                  field value.name, field: value
                end
                # Add the global node ID lookup query.
                if Rails.config.global_ids && type == :query
                  field :node, field: NodeIdentification.field
                end
              end
            end
            schema
          end
        end
        if Rails.config.global_ids
          @schema.node_identification = NodeIdentification
        end
        @schema
      end
    end
  end
end
