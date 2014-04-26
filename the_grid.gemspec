# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "the_grid/version"

Gem::Specification.new do |s|
  s.name        = "the_grid"
  s.version     = TheGrid::VERSION
  s.authors     = ["Sergiy Stotskiy", "Yuriy Buchchenko"]
  s.email       = "sergiy.stotskiy@gmail.com"
  s.homepage    = "http://github.com/stalniy/grid"
  s.license     = "MIT"
  s.summary     = %q{Yet another grid api.}
  s.platform    = Gem::Platform::RUBY

  s.description = <<-EOF
    Provides API for building response based on ActiveRecord::Relation objects (json, csv, even using custom view builder).
    It makes much easier to fetch information from database for displaying it for example using JavaScript MV* based frameworks (such as Knockout, Backbone, Angular, etc), in csv format or even with any custom format.

    Tags: json, csv, grid, api, grid builder, activerecord relation builder, relation
  EOF

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '>= 3.0'
  s.add_dependency 'json'

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.13"
end
