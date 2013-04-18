TheGrid.configure do |config|
  # Specifies scopes for custom commands
  # config.commands_lookup_scopes += %w{ command_scope_1 command_scope_2 }

  # Default number of items per page for pagination
  config.default_max_per_page = 25

  # Print json response with new lines and tabs
  config.prettify_json = Rails.env.development?
end
