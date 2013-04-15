shared_examples "for Grid View Builder" do
  before(:each) { subject.context.stub(:assemble => records) }

  it { should respond_to(:assemble_with) }

  it "merges context with params" do
    subject.api.should_receive(:compose!).with(params.merge subject.context.options)
    subject.assemble_with(params)
  end
end
