shared_examples "for Grid View Builder" do
  before(:each) { context.stub(:assemble => records) }
  before(:each) { TheGrid::Api.any_instance.stub(:compose!) }
  before(:each) { TheGrid::Api.any_instance.stub(:options => api_options) }

  let(:record)   {{ :id => 1, :name => "Name", :status => "Active", :text => "Text" }}
  let(:records)  {[ record, record, record ]}
  let(:api_options){{ :max_page => 25 }}

  it { should respond_to(:assemble) }
end
