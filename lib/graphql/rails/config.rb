module GraphQL
  module Rails
    extend self

    def configure
      yield config
    end

    def config
      @config ||= OpenStruct.new({
        # Should the GraphiQL web interface be served?
        :graphiql => ::Rails.env.development?,

        # Should names be converted to lowerCamelCase per GraphQL convention?
        # For example, should :get_user_tasks become 'getUserTasks'?
        :camel_case => true,

        # Should object IDs be globally unique?
        # This is necessary to conform to the Relay Global Object ID spec.
        :global_ids => true,

        # Should the following extensions be loaded?
        :mongoid => defined?(::Mongoid),
        :cancan => defined?(::CanCan),
      })
    end
  end
end
