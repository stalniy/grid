require 'spec_helper'

module GridCommands
  class Sort < Grid::Api::Command::Sort; end
end

describe Grid::Api::Command do
  subject{ Grid::Api::Command }
  let(:commands_scope) { GridCommands }

  it "can be executed on relation" do
    subject.find(:paginate).should respond_to(:execute_on)
  end

  it "build command instance" do
    subject.find(:paginate).should be_kind_of subject.const_get('Paginate')
  end

  it "build flyweight instances" do
    subject.find(:paginate).object_id.should eql subject.find(:paginate).object_id
  end

  it "raise error if command not found" do
    expect{ subject.find(:unknown_cmd) }.to raise_error ArgumentError
  end
  
  it "has only one scope for commands by default" do
    subject.scopes.should eql [ subject.to_s.underscore ]
  end

  context "when register new scope" do
    before(:each) { subject.register_lookup_scope commands_scope.to_s.underscore }

    it "put scope at the top" do
      subject.scopes.first.should eql commands_scope.to_s.underscore
    end

    it "build the first found command" do
      subject.find(:sort).should be_kind_of commands_scope.const_get('Sort')
    end
  end

end
