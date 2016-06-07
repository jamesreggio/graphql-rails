module GraphQL
  module Rails
    Engine.routes.draw do
      if Rails.config.graphiql
        # Empty :graphql_path will cause GraphiQL to use its own URL.
        mount GraphiQL::Rails::Engine => '/', :graphql_path => ''
      end

      post '/' => 'schema#execute'
    end
  end
end
