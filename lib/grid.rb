require 'grid/version'
require 'grid/api'
require 'grid/builder'
require 'grid/config'

module Grid
  def self.configure
    Config.new.tap{ |c| yield c }.apply
  end

  def self.build_for(relation)
    Api.new(relation)
  end
end
