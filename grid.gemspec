# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "grid/version"

Gem::Specification.new do |s|
  s.name        = "grid"
  s.version     = Grid::VERSION
  s.authors     = ["Sergiy Stotskiy"]
  s.email       = "sergiy.stotskiy@gmail.com"
  s.homepage    = "http://github.com/stalniy/grid"
  s.license     = "MIT"
  s.summary     = %q{Yet another grid api.}
  s.platform    = Gem::Platform::RUBY

  s.description = <<-EOF
Provides json API for building ActiveRecord::Relation's.  It makes much easier to fetch information from database for displaying it using JavaScript MV* based frameworks such as Knockout, Backbone, Angular, etc.

Tags: json, grid, api, MVVM, Knockout, Backbone, Angular, MVC, grid, grid dsl builder, activerecord relation builder
EOF

  # s.rubyforge_project = "grid"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 3.0"
  s.add_dependency 'activesupport', '>= 2.0.0'
  s.add_dependency 'json'

  # specify any dependencies here; for example:
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.13"
  s.add_development_dependency "rspec-mocks", "~> 2.13"
end
