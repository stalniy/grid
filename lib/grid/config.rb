module Grid
  class Config
    attr_accessor :default_max_per_page, :prettify_json, :commands_lookup_scopes

    def initialize
      self.commands_lookup_scopes = []
      self.prettify_json  = false
    end

    def apply
      self.commands_lookup_scopes.flatten.each{ |s| Api::Command.register_lookup_scope(s) }
      Api::Command.find(:paginate).default_per_page = self.default_max_per_page
      Builder::Json.prettify_json = self.prettify_json
    end
  end

  ActionView::Template.register_template_handler :grid_builder, ::Grid::Builder if defined?(ActionView::Template)
end