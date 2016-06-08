module GraphQL
  module Rails
    # Base type for operations classes in the Rails app.
    # Operations are specified in a manner similar to controller actions, and
    # can access variables and state localized to the current operation.
    # Classes can define callbacks similar to controller 'filters'.
    class Operations
      extend Forwardable
      include Callbacks

      # Initialize an instance with state pertaining to the current operation.
      # Accessors for this state are created and proxied through to the
      # specified options hash.
      def initialize(options = {})
        @options = OpenStruct.new(options)
        self.class.instance_eval do
          def_delegators :@options, *options.keys
        end
      end

      # Define a query operation.
      # Definitions should have the following form:
      #
      #   query :find_cats => [Cat] do
      #     description 'This query returns a list of Cat models'
      #     argument :age, Integer, :required
      #     argument :breed, String
      #     resolve do
      #       raise 'Too old' if args[:age] > 20
      #       Cat.find(age: args[:age], breed: args[:breed])
      #     end
      #   end
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

      private

      # DSL for query definition.
      class QueryDefinition < DSL
        attr_reader :field

        def initialize(klass)
          @klass = klass
          @field = ::GraphQL::Field.new
        end

        def name(name)
          @name = name
          @field.name = Types.to_name(name)
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
          argument.name = Types.to_name(name)
          argument.type = Types.resolve(type, required == :required)
          @field.arguments[argument.name] = argument
        end

        def resolve(&block)
          field.resolve = -> (obj, args, ctx) do
            # Instantiate the Operations class with state on this query.
            instance = @klass.new({
              op: :query, name: @name, type: @type,
              obj: obj, args: args, ctx: ctx, context: ctx
            })

            begin
              # Run callbacks for this Operations class.
              instance.run_callbacks(:perform_operation) do
                # Call out to the app-defined resolver.
                instance.instance_eval(&block)
              end
            rescue => e
              # Surface messages from standard errors in GraphQL response.
              ::GraphQL::ExecutionError.new(e.message)
            rescue ::Exception => e
              # Log and genericize other runtime errors.
              Rails.logger.error "Unexpected exception during query: #{@name}"
              Rails.logger.exception e
              ::GraphQL::ExecutionError.new('Internal error')
            end
          end
        end
      end

      # Extract parts from a hash passed to the operation definition DSL.
      def self.extract_pair(hash)
        unless hash.length == 1
          raise 'Hash must contain a single :name => Type pair.'
        end
        {name: hash.keys.first, type: hash.values.first}
      end
    end
  end
end
