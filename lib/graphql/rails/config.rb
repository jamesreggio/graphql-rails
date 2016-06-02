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

        # Should the /app/graph directory automatically reload upon changes?
        :autoload => ::Rails.env.development?,

        # Should names be converted to lowerCamelCase per GraphQL convention?
        # For example, should :get_user_tasks become 'getUserTasks'?
        :camel_case => true,

        # Should Mongoid type extensions be loaded?
        :mongoid => defined?(::Mongoid)
      })
    end
  end
end
