require 'spec_helper'

describe TheGrid::Config do
  context "when initializes" do
    its(:commands_lookup_scopes) { should eql [] }
    its(:prettify_json) { should be_false }
  end

  context "when applying specified values" do
    let(:command) { TheGrid::Api::Command }
    let(:builder) { TheGrid::Builder::Json }
    before(:each) { configure(subject) }

    it "registers specified lookup scopes from configuration" do
      command.scopes.should include(*subject.commands_lookup_scopes)
    end

    it "sets up default_per_page for Paginate command" do
      command.find(:paginate).default_per_page.should eql subject.default_max_per_page
    end

    it "sets up prettify_json option for json builder" do
      builder.prettify_json.should eql subject.prettify_json
    end
  end

private

  def configure(config)
    config.commands_lookup_scopes += %w{ command_scope_1 command_scope_2 }
    config.default_max_per_page = 10
    config.prettify_json = true
    config.apply
  end
end
