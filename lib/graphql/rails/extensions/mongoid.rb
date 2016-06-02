# TODO: Limit to one ORM, then support multiple ORMs.
module GraphQL
  module Rails
    if Rails.config.mongoid
      module Mongoid
        Rails.logger.debug 'Loading Mongoid extensions'

        Types.add_type ::Mongoid::Boolean, Boolean
        Types.add_type BSON::ObjectId, String
        Types.add_type DateTime, String
        Types.add_type Object, String
        Types.add_type Hash, String

        Types.add_builder do |type|
          next unless type.included_modules.include?(::Mongoid::Document)
          Rails.logger.debug "Building Mongoid::Document type: #{type.name}"

          # TODO: Support parent types/interfaces.
          GraphQL::ObjectType.define do
            name type.name

            type.fields.each_value do |field_value|
              field field_value.name do
                type -> { Types.resolve(field_value.type) }
                description field_value.label unless field_value.label.blank?
              end
            end

            type.relations.each_value do |relationship|
              # TODO: Add polymorphic support.
              if relationship.polymorphic?
                msg = "Skipping polymorphic relationship: #{relationship.name}"
                Rails.logger.warn msg
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

        GraphQL::Relay::BaseConnection.register_connection_implementation(
          ::Mongoid::Relations::Targets::Enumerable,
          GraphQL::Relay::RelationConnection
        )
      end
    end
  end
end
