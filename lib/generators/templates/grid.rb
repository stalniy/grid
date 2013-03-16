Grid.configure do |config|
  # TODO: will not work in development mode when model's file is reloaded
  config.commands_lookup_scopes += %w{ test/a/b new/ba/s }
  config.default_max_per_page = 5
  config.prettify_json = true

  ActionView::Template.register_template_handler :grid_builder, ::Grid::Builder if defined?(ActionView::Template)
end