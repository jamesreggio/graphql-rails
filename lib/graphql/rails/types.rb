module GraphQL
  module Rails
    # Type system responsible for resolving GraphQL types.
    # Delegates creation of GraphQL types to ORM-specific extensions.
    module Types
      extend self

      # Clear internal state, probably due to a Rails reload.
      def clear
        @types = nil
        extensions.each do |extension|
          extension.clear
        end
      end

      # Resolve an arbitrary type to a GraphQL type.
      # Lists can be specified with single-element arrays; for example:
      # [String] resolves to a list of GraphQL::STRING_TYPE objects.
      def resolve(type, required = false)
        if type.nil?
          raise 'Cannot resolve nil type'
        elsif required
          resolve(type).to_non_null_type
        elsif type.is_a?(GraphQL::BaseType)
          type
        elsif type.is_a?(Array)
          unless type.length == 1
            raise 'Lists must be specified with single-element arrays'
          end
          resolve(type.first).to_list_type
        elsif types.include?(type)
          resolve(types[type])
        else
          resolve(try_extensions(:resolve, type) || begin
            # TODO: Decide whether to use String as a fallback, or raise.
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

      # Convert a type name to a string with the correct convention,
      # applying an optional namespace.
      def to_type_name(name, namespace = '')
        return namespace + to_type_name(name) unless namespace.blank?
        name = name.to_s
        name = name.camelize(:upper) if Rails.config.camel_case
        name = name.gsub(/\W/, '_')
        name
      end

      # Convert a field name to a string with the correct convention.
      def to_field_name(name)
        # camelize strips leading underscores, which is undesirable.
        if name.to_s.starts_with?('_')
          "_#{to_field_name(name.to_s[1..-1])}"
        elsif Rails.config.camel_case
          name.to_s.camelize(:lower)
        else
          name.to_s
        end
      end

      private

      # Default mapping of built-in scalar types to GraphQL types.
      def types
        @types ||= {
          String => GraphQL::STRING_TYPE,

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

      # List of registered extensions.
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
