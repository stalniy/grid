require 'grid/version'
require 'grid/api'
require 'grid/api/command'
require 'grid/api/command/batch'
require 'grid/builder'
require 'grid/config'
Dir.chdir(File.dirname(__FILE__)) do
  Dir['grid/builder/**/*.rb', 'grid/api/command/**/*.rb'].each{ |f| require f }
end

module Grid
  def self.configure
    Config.new.tap{ |c| yield c }.apply
  end

  def self.build_for(relation)
    Api.new(relation)
  end
end
