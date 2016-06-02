module GraphQL
  module Rails
    Engine.routes.draw do
      if Rails.config.graphiql
        mount GraphiQL::Rails::Engine => '/', :graphql_path => :self
      end

      post '/' => 'schema#execute'
    end
  end
end
