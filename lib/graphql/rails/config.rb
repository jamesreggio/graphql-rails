module GraphQL
  module Rails
    extend self

    # Yields the configuration object to a block, per convention.
    def configure
      yield config
    end

    # Configuration for this gem.
    def config
      @config ||= OpenStruct.new({
        # Should graphql-ruby be placed into debug mode?
        :debug => ::Rails.env.development?,

        # Should the GraphiQL web interface be served?
        :graphiql => ::Rails.env.development?,

        # Should names be converted to lowerCamelCase per GraphQL convention?
        # For example, should :get_user_tasks become 'getUserTasks'?
        :camel_case => true,

        # Should object IDs be globally unique?
        # This is necessary to conform to the Relay Global Object ID spec.
        :global_ids => true,

        # Maximum nesting for GraphQL queries.
        # Specify nil for unlimited nesting depth.
        :max_depth => 8,

        # Should the following extensions be loaded?
        :mongoid => defined?(::Mongoid),
        :cancan => defined?(::CanCan),
      })
    end
  end
end
