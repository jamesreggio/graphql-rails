$:.push File.expand_path('../lib', __FILE__)

require 'graphql/rails/version'

Gem::Specification.new do |s|
  s.name        = 'graphql-rails'
  s.version     = GraphQL::Rails::VERSION
  s.license     = 'MIT'
  s.authors     = ['James Reggio']
  s.email       = ['james.reggio@gmail.com']
  s.homepage    = 'https://github.com/jamesreggio/graphql-rails'
  s.summary     = 'Zero-configuration GraphQL + Relay support for Rails'
  s.description = <<-EOM
Zero-configuration GraphQL + Relay support for Rails. Adds a route to process
GraphQL operations and provides a visual editor (GraphiQL) during development.
Allows you to specify GraphQL queries and mutations as though they were
controller actions. Automatically maps Mongoid models to GraphQL types.
Seamlessly integrates with CanCan.
  EOM
  s.required_ruby_version = '>= 2.1.0'

  s.files       = Dir['{app,config,lib}/**/*', 'LICENSE']
  s.required_ruby_version = '>= 2.1.0'

  s.add_dependency 'rails', '~> 4'
  s.add_dependency 'graphql', '~> 0.13'
  s.add_dependency 'graphql-relay', '~> 0.9'
  s.add_dependency 'graphiql-rails', '~> 1.2'
end
