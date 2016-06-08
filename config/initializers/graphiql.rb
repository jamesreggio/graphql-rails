# There is no apparent harm to enabling CSRF token-passing for GraphiQL, even
# if the Rails app doesn't use CSRF protection.
GraphiQL::Rails.config.csrf = true
