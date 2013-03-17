module Grid
  require 'grid/version'
  require 'grid/builder'
  require 'grid/api'
  require 'grid/config'

  def self.configure
    Config.new.tap{ |c| yield c }.apply
  end

  def self.build_for(relation)
    Api.new(relation)
  end
end
