require "spec_helper"

describe Grid::Api do
  subject{ Grid::Api.new(relation) }

  let(:child_relation) { double("Child Relation").as_null_object }
  let(:relation) { double("Relation", :reflections => { :child_relation => child_relation }).as_null_object }
  let(:commands) { lambda{ |name| ::Grid::Api::Command.find(name) } }

  context "when run single command" do
    let(:options)  {{ :field => "title", :order => "desc" }}
    let(:cmd_name) { :sort }

    after(:each) { subject.run_command!(cmd_name, options) }

    it "run specified command" do
      commands[cmd_name].should_receive(:execute_on).with(subject.relation, options)
    end

    it "should be prepared by command instance" do
      commands[cmd_name].should_receive(:contextualize).with(subject.relation, options).and_return({})
    end

    it "run delegated command on specified target" do
      subject.delegate(cmd_name => :child_relation)
      commands[cmd_name].should_receive(:execute_on).with(child_relation, options)
    end
  end

  context "when run few commands" do
    let(:params)  {{ :cmd => [:sort, :search, :batch_update], :field => "title", :query => "test" }}
    before(:each) { subject.stub(:run_command!) }
    after(:each)  { subject.build_with!(params) }

    it "skip batch commands" do
      commands[:batch_update].should_not_receive(:execute_on)
    end

    it "run specified commands" do
      subject.should_receive(:run_command!).with(:sort, params)
      subject.should_receive(:run_command!).with(:search, params)
    end

    it "adds paginate command by default" do
      subject.should_receive(:run_command!).with(:paginate, params)
    end

    it "doesn't add paginate command if per_page equals false" do
      params[:per_page] = false
      subject.should_not_receive(:run_command!).with(:paginate, params)
    end

    it "delegates specified commands" do
      params[:delegate] = {:sort => child_relation}
      subject.should_receive(:delegate).with(params[:delegate])
    end
  end
end