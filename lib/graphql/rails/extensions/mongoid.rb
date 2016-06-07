module GraphQL
  module Rails
    if Rails.config.mongoid
      Rails.logger.debug 'Loading Mongoid extensions'

      GraphQL::Relay::BaseConnection.register_connection_implementation(
        ::Mongoid::Relations::Targets::Enumerable,
        GraphQL::Relay::RelationConnection
      )

      module Mongoid
        extend self

        NAMESPACE = 'MG'

        def clear
          @types = nil
        end

        def resolve(type)
          types[type] || build_type(type)
        end

        def lookup(type_name, id)
          return if Types.use_namespaces? && !type_name.starts_with?(NAMESPACE)
          types.each_pair do |type, graph_type|
            return type.find(id) if graph_type.name == type_name
          end
          nil
        end

        private

        def types
          @types ||= {
            ::Mongoid::Boolean => GraphQL::BOOLEAN_TYPE,
            BSON::ObjectId => GraphQL::STRING_TYPE,
          }
        end

        def build_type(type)
          return nil unless type.included_modules.include?(::Mongoid::Document)
          Rails.logger.debug "Building Mongoid::Document type: #{type.name}"

          # TODO: Support parent types/interfaces.
          type_name = to_name(type)
          types[type] = GraphQL::ObjectType.define do
            name type_name

            if Rails.config.global_ids
              interfaces [NodeIdentification.interface]
              global_id_field :id
            end

            type.fields.each_value do |field_value|
              field field_value.name do
                type -> { Types.resolve(field_value.type) }
                description field_value.label unless field_value.label.blank?
              end
            end

            type.relations.each_value do |relationship|
              # TODO: Add polymorphic support.
              if relationship.polymorphic?
                Rails.logger.warn(
                  "Skipping polymorphic relationship: #{relationship.name}"
                )
                next
              end

              if relationship.many?
                connection relationship.name do
                  type -> { Types.resolve(relationship.klass).connection_type }
                end
              else
                field relationship.name do
                  type -> { Types.resolve(relationship.klass) }
                end
              end
            end
          end
        end

        def to_name(type)
          if Types.use_namespaces?
            NAMESPACE + type.name
          else
            type.name
          end
        end
      end

      Types.add_extension Mongoid
    end
  end
end
