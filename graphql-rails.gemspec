$:.push File.expand_path('../lib', __FILE__)

require 'graphql/rails/version'

Gem::Specification.new do |s|
  s.name        = 'graphql-rails'
  s.version     = GraphQL::Rails::VERSION
  s.authors     = ['James Reggio']
  s.email       = ['james.reggio@gmail.com']
  s.homepage    = 'https://github.com/jamesreggio/graphql-rails'
  s.summary     = 'Zero-configuration GraphQL + Relay support for Rails'
  s.description = 'TODO'
  s.license     = 'MIT'

  s.files       = Dir['{app,config,lib}/**/*', 'README.md', 'LICENSE']

  s.add_dependency 'rails', '~> 4'
  s.add_dependency 'graphql', '~> 0.13'
  s.add_dependency 'graphql-relay', '~> 0.9'
  s.add_development_dependency 'sqlite3'
end
