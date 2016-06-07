module GraphQL
  module Rails
    class Operations
      extend Forwardable
      include Callbacks

      def initialize(options = {})
        @options = OpenStruct.new(options)
        self.class.instance_eval do
          def_delegators :@options, *options.keys
        end
      end

      def self.query(hash, &block)
        hash = extract_pair(hash)
        Rails.logger.debug "Adding query: #{to_name(hash[:name])}"

        definition = QueryDefinition.new(self)
        definition.run(&block)
        definition.run do
          name hash[:name]
          type hash[:type]
        end
        Schema.add_query definition.field
      end

      # TODO: Implement mutations and subscriptions.
      # TODO: Implement model functions (only, exclude, rename, etc.)

      private

      def self.extract_pair(hash)
        unless hash.length == 1
          raise 'Hash must contain a single :name => Type pair.'
        end
        {name: hash.keys.first, type: hash.values.first}
      end

      # TODO: Ensure consistent naming convention around everything.
      def self.to_name(symbol)
        if Rails.config.camel_case
          symbol.to_s.camelize(:lower)
        else
          symbol.to_s
        end
      end

      class QueryDefinition < DSL
        attr_reader :field

        def initialize(klass)
          @klass = klass
          @field = ::GraphQL::Field.new
        end

        def name(name)
          @name = name
          @field.name = to_name(name)
        end

        def type(type)
          @type = type
          @field.type = Types.resolve(type)
        end

        def description(description)
          @field.description = description
        end

        def argument(name, type, required = false)
          argument = ::GraphQL::Argument.new
          argument.name = to_name(name)
          argument.type = Types.resolve(type, required == :required)
          @field.arguments[argument.name] = argument
        end

        def resolve(&block)
          field.resolve = -> (obj, args, ctx) do
            instance = @klass.new({
              op: :query, name: @name, type: @type,
              obj: obj, args: args, ctx: ctx
            })

            begin
              instance.run_callbacks(:perform_operation) do
                instance.instance_eval(&block)
              end
            rescue => e
              ::GraphQL::ExecutionError.new(e.message)
            rescue ::Exception => e
              Rails.logger.error "Unexpected exception during query: #{@name}"
              Rails.logger.exception e
              ::GraphQL::ExecutionError.new('Internal error')
            end
          end
        end
      end
    end
  end
end
