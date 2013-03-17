module Grid
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer
        template "grid.rb", "config/initializers/grid.rb"
      end
    end
  end
end