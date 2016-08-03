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
        Rails.logger.debug "Adding query: #{Types.to_field_name(hash[:name])}"

        definition = QueryDefinition.new(self)
        definition.run(&block)
        definition.run do
          name hash[:name]
          type hash[:type]
        end
        Schema.add_query definition.field
      end

      # Define a mutation operation.
      # Definitions should have the following form:
      #
      #   mutation :feed_cat => {appetite: Integer, last_meal: DateTime} do
      #     description 'This mutation feeds the cat and returns its appetite'
      #     argument :cat_id, Integer, :required
      #     argument :mouse_id, Integer, :required
      #     resolve do
      #       cat = Cat.find(args[:cat_id])
      #       mouse = Mouse.find(args[:mouse_id])
      #       raise 'Cannot find cat or mouse' if cat.nil? || mouse.nil?
      #
      #       cat.feed(mouse)
      #       {appetite: cat.appetite, last_meal: DateTime.now}
      #     end
      #   end
      def self.mutation(hash, &block)
        hash = extract_pair(hash)
        unless hash[:type].is_a?(Hash)
          raise 'Mutations must be specified with Hash results'
        end
        Rails.logger.debug "Adding mutation: #{Types.to_field_name(hash[:name])}"

        definition = MutationDefinition.new(self)
        definition.run(&block)
        definition.run do
          name hash[:name]
          type hash[:type]
        end
        Schema.add_mutation definition.field
      end

      # TODO: Implement subscriptions.

      private

      # DSL for query definition.
      # TODO: Support resolve-only blocks.
      class QueryDefinition < DSL
        attr_reader :field

        def initialize(klass)
          @klass = klass
          @field = ::GraphQL::Field.new
        end

        def name(name)
          @name = name
          @field.name = Types.to_field_name(name)
        end

        def type(type)
          @type = type
          @field.type = Types.resolve(type)
        end

        def description(description)
          @field.description = description
        end

        def argument(name, type, required = false)
          argument = ::GraphQL::Argument.define do
            name Types.to_field_name(name)
            type Types.resolve(type, required == :required)
          end
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

      # DSL for mutation definition.
      class MutationDefinition < QueryDefinition
        def initialize(klass)
          super
          @input = ::GraphQL::InputObjectType.new
          @output = ::GraphQL::ObjectType.new
        end

        def type(hash)
          hash.each do |name, type|
            field = ::GraphQL::Field.define do
              name Types.to_field_name(name)
              type Types.resolve(type)
            end
            @output.fields[field.name] = field
          end
        end

        def argument(name, type, required = false)
          argument = ::GraphQL::Argument.define do
            name Types.to_field_name(name)
            type Types.resolve(type, required == :required)
          end
          @input.arguments[argument.name] = argument
        end

        def field
          input = @input
          input.name = "#{@field.name}Input"
          input.description = "Generated input type for #{@field.name}"
          input.arguments['clientMutationId'] = ::GraphQL::Argument.define do
            name 'clientMutationId'
            type Types.resolve(::String)
            description 'Unique identifier for client performing mutation'
          end

          output = @output
          output.name = "#{@field.name}Output"
          output.description = "Generated output type for #{@field.name}"
          output.fields['clientMutationId'] = ::GraphQL::Field.define do
            name 'clientMutationId'
            type Types.resolve(::String)
            description 'Unique identifier for client performing mutation'
          end

          @field.type = output
          @field.arguments['input'] = ::GraphQL::Argument.define do
            name 'input'
            type Types.resolve(input, true)
          end
          @field
        end

        def resolve(&block)
          field.resolve = -> (obj, args, ctx) do
            # Instantiate the Operations class with state on this query.
            instance = @klass.new({
              op: :mutation, name: @name, type: @type,
              obj: obj, args: args[:input], ctx: ctx, context: ctx
            })

            begin
              # Run callbacks for this Operations class.
              instance.run_callbacks(:perform_operation) do
                # Call out to the app-defined resolver.
                result = instance.instance_eval(&block)
                result[:clientMutationId] = args[:clientMutationId]
                ::OpenStruct.new(result)
              end
            rescue => e
              # Surface messages from standard errors in GraphQL response.
              ::GraphQL::ExecutionError.new(e.message)
            rescue ::Exception => e
              # Log and genericize other runtime errors.
              Rails.logger.error "Unexpected exception during mutation: #{@name}"
              Rails.logger.exception e
              ::GraphQL::ExecutionError.new('Internal error')
            end
          end
        end
      end

      # Extract parts from a hash passed to the operation definition DSL.
      def self.extract_pair(hash)
        unless hash.length == 1
          raise 'Hash must contain a single :name => Type pair'
        end
        {name: hash.keys.first, type: hash.values.first}
      end
    end
  end
end
