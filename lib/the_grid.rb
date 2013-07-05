require 'the_grid/version'
require 'the_grid/api'
require 'the_grid/api/command'
require 'the_grid/builder'
require 'the_grid/config'

module TheGrid
  def self.configure
    Config.new.tap{ |c| yield c }.apply
  end

  def self.build_for(relation)
    Api.new(relation)
  end
end
