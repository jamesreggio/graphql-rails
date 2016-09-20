module GraphQL
  module Rails
    if Rails.config.mongoid
      Rails.logger.debug 'Loading Mongoid extensions'

      # Use the built-in RelationConnection to handle Mongoid relations.
      GraphQL::Relay::BaseConnection.register_connection_implementation(
        ::Mongoid::Relations::Targets::Enumerable,
        GraphQL::Relay::RelationConnection
      )

      # Mongoid type extension for the GraphQL type system.
      module Mongoid
        extend self

        # Clear internal state, probably due to a Rails reload.
        def clear
          @types = nil
        end

        # Resolve an arbitrary type to a GraphQL type.
        # Returns nil if the type isn't a Mongoid document.
        def resolve(type)
          types[type] || build_type(type)
        end

        # Lookup an arbitrary object from its GraphQL type name and ID.
        def lookup(type_name, id)
          return unless type_name.starts_with?(namespace)
          types.each_pair do |type, graph_type|
            return type.find(id) if graph_type.name == type_name
          end
          nil
        end

        private

        # Namespace for Mongoid types, if namespaces are required.
        def namespace
          if Types.use_namespaces?
            'MG'
          else
            ''
          end
        end

        # Cached mapping of Mongoid types to GraphQL types, initialized with
        # mappings for common built-in scalar types.
        def types
          @types ||= {
            Boolean => GraphQL::BOOLEAN_TYPE,
            ::Mongoid::Boolean => GraphQL::BOOLEAN_TYPE,
            BSON::ObjectId => GraphQL::STRING_TYPE,
          }
        end

        # Build a GraphQL type for a Mongoid document.
        # Returns nil if the type isn't a Mongoid document.
        def build_type(type)
          return nil unless type.included_modules.include?(::Mongoid::Document)
          Rails.logger.debug "Building Mongoid::Document type: #{type.name}"

          # Build and cache the GraphQL type.
          # TODO: Map type inheritance to GraphQL interfaces.
          type_name = Types.to_type_name(type.name, namespace)
          types[type] = GraphQL::ObjectType.define do
            name type_name

            # Add the global node ID, if enabled; otherwise, document ID.
            if Rails.config.global_ids
              interfaces [NodeIdentification.interface]
              global_id_field :id
            else
              field :id do
                type -> { Types.resolve(BSON::ObjectId) }
              end
            end

            # Add each field from the document.
            # TODO: Support field exclusion and renaming.
            type.fields.each_value do |field_value|
              field Types.to_field_name(field_value.name) do
                property field_value.name.to_sym
                type -> { Types.resolve(field_value.type) }
                description field_value.label unless field_value.label.blank?
              end
            end

            # Add each relationship from the document as a Relay connection.
            type.relations.each_value do |relationship|
              # TODO: Add polymorphic support.
              if relationship.polymorphic?
                Rails.logger.warn(
                  "Skipping polymorphic relationship: #{relationship.name}"
                )
                next
              end

              # Check that relationship has a valid type.
              begin
                klass = relationship.klass
              rescue
                Rails.logger.warn(
                  "Skipping relationship with invalid class: #{relationship.name}"
                )
                next
              end

              if relationship.many?
                connection Types.to_field_name(relationship.name) do
                  property relationship.name.to_sym
                  type -> { Types.resolve(klass).connection_type }
                end
              else
                field Types.to_field_name(relationship.name) do
                  property relationship.name.to_sym
                  type -> { Types.resolve(klass) }
                end
              end
            end
          end
        end
      end

      Types.add_extension Mongoid
    end
  end
end
