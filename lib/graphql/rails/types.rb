module GraphQL
  module Rails
    module Types
      extend self

      # Resolve an arbitrary type to a GraphQL type.
      def resolve(type, required = false)
        if type.nil?
          raise 'Cannot resolve nil type.'
        elsif required
          resolve(type).to_non_null_type
        elsif type.is_a?(GraphQL::BaseType)
          type
        elsif type.is_a?(Array)
          unless type.length == 1
            raise 'Lists must be specified with single-element arrays.'
          end
          resolve(type.first).to_list_type
        elsif types.include?(type)
          resolve(types[type])
        else
          resolve(build(type))
        end
      end

      def add_builder(&block)
        builders.push block
      end

      def add_type(type, graph_type)
        if types.include?(type)
          Rails.logger.warn "Redefining GraphQL type for: #{type.name}"
        else
          Rails.logger.debug "Adding GraphQL type for: #{type.name}"
        end
        types[type] = graph_type
      end

      private

      def types
        @types ||= {
          Boolean => GraphQL::BOOLEAN_TYPE,
          String => GraphQL::STRING_TYPE,
          Integer => GraphQL::INT_TYPE,
          Float => GraphQL::FLOAT_TYPE,
          DateTime => GraphQL::STRING_TYPE,
          Time => GraphQL::STRING_TYPE,
        }
      end

      def builders
        @builders ||= []
      end

      def build(type)
        graph_type = nil
        builders.each do |builder|
          graph_type = builder.call(type)
          break unless graph_type.nil?
        end
        add_type(type, graph_type) unless graph_type.nil?
        graph_type || String # HACK
      end
    end
  end
end
