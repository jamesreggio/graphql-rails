module GraphQL
  module Rails
    module Types
      extend self

      def clear
        @types = nil
        extensions.each do |extension|
          extension.clear
        end
      end

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
          resolve(try_extensions(:resolve, type) || begin
            # TODO: Remove this hack.
            Rails.logger.warn "Unable to resolve type: #{type.name}"
            String
          end)
        end
      end

      # Lookup an arbitrary object from its GraphQL type name and ID.
      def lookup(type_name, id)
        try_extensions(:lookup, type_name, id)
      end

      # Should extensions namespace their type names?
      # This is necessary if multiple extensions are loaded, so as to avoid
      # collisions in the shared type namespace.
      def use_namespaces?
        extensions.count > 1
      end

      # Add an extension to the type system.
      # Generally, each ORM will have its own extension.
      def add_extension(extension)
        extensions.push extension
      end

      private

      # Default mapping of built-in scalar types to GraphQL types.
      def types
        @types ||= {
          String => GraphQL::STRING_TYPE,
          Boolean => GraphQL::BOOLEAN_TYPE,

          Fixnum => GraphQL::INT_TYPE,
          Integer => GraphQL::INT_TYPE,
          Float => GraphQL::FLOAT_TYPE,

          Date => GraphQL::STRING_TYPE,
          Time => GraphQL::STRING_TYPE,
          DateTime => GraphQL::STRING_TYPE,

          Array => GraphQL::STRING_TYPE,
          Object => GraphQL::STRING_TYPE,
          Hash => GraphQL::STRING_TYPE,
        }
      end

      def extensions
        @extensions ||= []
      end

      # Try a function on each extension, and return the result from
      # the first extension that returns a non-nil value.
      def try_extensions(method, *args, &block)
        extensions.each do |extension|
          result = extension.send(method, *args, &block)
          return result unless result.nil?
        end
        nil
      end
    end
  end
end
