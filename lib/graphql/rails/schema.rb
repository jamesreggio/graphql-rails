module GraphQL
  module Rails
    module Schema
      extend self

      def clear
        @schema = nil
        @fields = Hash.new { |hash, key| hash[key] = [] }
      end

      TYPES = [:query, :mutation, :subscription]

      TYPES.each do |type|
        define_method "add_#{type.to_s}" do |field|
          @schema = nil # Invalidate cached schema.
          @fields[type].push field
        end
      end

      def instance
        # TODO: Support max_depth and types.
        # TODO: Sweep available options and expose in config.
        @schema ||= GraphQL::Schema.new begin
          TYPES.reduce({}) do |schema, type|
            fields = @fields[type]
            unless fields.empty?
              schema[type] = GraphQL::ObjectType.define do
                name type.to_s.capitalize
                description "Root #{type.to_s} for this schema"
                fields.each do |value|
                  field value.name, field: value
                end
                if Rails.config.global_ids && type == :query
                  field :node, field: NodeIdentification.field
                end
              end
            end
            schema
          end
        end
      end
    end
  end
end
