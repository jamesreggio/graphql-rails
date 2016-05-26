class GraphQL::Rails::Engine < ::Rails::Engine
  initializer 'graphql-rails.autoload', :before => :set_autoload_paths do |app|
    app.config.autoload_paths += %W(#{app.config.root}/app/graph/fields)
    app.config.autoload_paths += %W(#{app.config.root}/app/graph/types)
  end
end
