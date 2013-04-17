require 'spec_helper'

describe TheGrid::Builder::Json do
  subject { TheGrid::Builder::Json.new(relation, context) }

  before(:each) { subject.api.stub(:compose!) { subject.api.options[:max_page] = 25 } }

  let(:relation) { double('Relation').as_null_object }
  let(:context) { create_context.tap { |c| c.stub(:assemble => [1,2,3,4]) } }
  let(:params) {{  :cmd => [:sort], :field => :name, :order => :desc }}

  let(:meta) {{ "meta" => {"api_key" => context.options[:api_key]}, "columns" => columns }}
  let(:columns) { context.visible_columns.stringify_keys.map{ |n, o| o.merge "column_name" => n } }
  let(:json_schema) {{ "max_page" => 25, "items" => context.assemble }}
  let(:assembled_result) { JSON.parse(subject.assemble_with(params)) }

  it "merges params with context options" do
    subject.api.should_receive(:compose!).with(params.merge context.options)
    subject.assemble_with params
  end

  it "generates json with meta information" do
    params[:with_meta] = true
    assembled_result.should eql json_schema.merge(meta)
  end

  it "generates json without meta" do
    assembled_result.should eql json_schema
  end

  it "generates json notification when get wrong argument" do
    subject.api.stub(:compose!) { raise ArgumentError, "123" }
    assembled_result.should eql({"status" => "error", "message" => "123"})
  end


  def create_context
    TheGrid::Builder::Context.new do
      api_key "hello_world"
      delegate  :sort => :articles, :filter => :articles

      column :name
      column :is_active
    end
  end

end
