module TheGrid
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer
        template "the_grid.rb", "config/initializers/the_grid.rb"
      end
    end
  end
end