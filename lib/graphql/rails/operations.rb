module GraphQL
  module Rails
    class Operations
      def self.query(hash, &block)
        hash = extract_pair(hash)
        Rails.logger.debug "Adding query: #{to_name(hash[:name])}"

        definition = QueryDefinition.new
        definition.run(&block)
        definition.run do
          name hash[:name]
          type hash[:type]
        end
        Schema.add_query definition.field
      end

      private

      def self.extract_pair(hash)
        unless hash.length == 1
          raise 'Hash must contain a single :name => Type pair.'
        end
        {name: hash.keys.first, type: hash.values.first}
      end

      def self.to_name(symbol)
        if Rails.config.camel_case
          symbol.to_s.camelize(:lower)
        else
          symbol.to_s
        end
      end

      class QueryDefinition < DSL
        attr_reader :field

        def initialize
          # TODO: Determine why root scoping is necessary.
          @field = ::GraphQL::Field.new
        end

        def name(name)
          @field.name = to_name(name)
        end

        def type(type)
          @field.type = Types.resolve(type)
        end

        def argument(name, type, required = false)
          # TODO: Determine why root scoping is necessary.
          argument = ::GraphQL::Argument.new
          argument.name = to_name(name)
          argument.type = Types.resolve(type, required == :required)
          @field.arguments[argument.name] = argument
        end

        def execute(&block)
          field.resolve = -> (obj, args, ctx) do
            HashDSL.new({obj: obj, args: args, ctx: ctx}).run(&block)
          end
        end
      end
    end
  end
end
