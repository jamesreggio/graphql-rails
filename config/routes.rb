Rails.application.routes.draw do
  # TODO: Support all verbs
  # TODO: Load path from configuration
  post '/api/graph' => 'graphql/rails/api#execute'
end
