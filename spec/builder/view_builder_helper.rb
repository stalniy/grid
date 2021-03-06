shared_examples "for Grid View Builder" do
  before(:each) { context.stub(:assemble => records) }
  before(:each) { TheGrid::Api.any_instance.stub(:compose!) }
  before(:each) { TheGrid::Api.any_instance.stub(:options => api_options) }

  let(:records)  {[ record, record, record ]}
  let(:api_options){{ :max_page => 25 }}

  it { should respond_to(:assemble) }

  def child_record(id)
  	{ :child_id => id, :child_name => "Child Name #{id}" }
  end

  def record(id = nil)
  	{ :id => id || 1, :name => "Name #{id}", :status => "Active", :text => "Text" }
  end

  def build_double(id, *methods)
    impl = methods.each_with_object({ :id => id }) do |method, object|
      object[method] = "#{method.to_s.titleize} #{id}"
    end
    impl[:values] = impl.values
    double(impl)
  end

end
