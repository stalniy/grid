module Grid
  require 'grid/version'
  require 'grid/config'
  require 'grid/api'
  require 'grid/api/command'
  require 'grid/builder'

  def self.configure
    Config.new.tap{ |c| yield c }.apply
  end

  def self.build_for(relation)
    Api.new(relation)
  end
end
