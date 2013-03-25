require 'spec_helper'

describe Grid::Config do
  context "when initializes" do

    it "initializes command_lookup_scopes with empty array by default" do
      subject.commands_lookup_scopes.should eql []
    end

    it "doesn't uses prettify_json option by default" do
      subject.prettify_json.should be_false
    end
  end

  context "when applying specified values" do
    before(:each) do
      # because class variables stores between tests
      Grid::Api::Command.class_variable_set :@@scopes, nil
      subject.commands_lookup_scopes += %w{ command_scope_1 command_scope_2 }
      subject.default_max_per_page = 10
      subject.prettify_json = true
      subject.apply
    end

    it "registers specified lookup scopes from configuration" do
      Grid::Api::Command.scopes.should == [
        "command_scope_2",
        "command_scope_1",
        "grid/api/command",
      ]
    end

    it "sets up default_per_page for Paginate command" do
      Grid::Api::Command.find(:paginate).default_per_page.should eql 10
    end

    it "sets up prettify_json option for json builder" do
      Grid::Builder::Json.prettify_json.should be_true
    end
  end
end
