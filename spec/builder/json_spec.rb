require 'spec_helper'
require_relative 'view_builder_helper'

describe TheGrid::Builder::Json do
  subject{ TheGrid::Builder::Json.new(Object.new, build_context) }

  include_examples "for Grid View Builder"
  before(:each) { subject.api.stub(:compose!){ subject.api.options[:max_page] = 25 } }

  let(:records) {[ 1, 2, 3, 4 ]}
  let(:params)  {{ :cmd => [:sort], :field => :name, :order => :desc }}

  let(:meta) {{ "meta" => {"api_key" => subject.context.options[:api_key]}, "columns" => columns }}
  let(:columns) { subject.context.visible_columns.stringify_keys.map{ |n, o| o.merge "name" => n } }
  let(:json_schema) {{ "max_page" => 25, "items" => subject.context.assemble }}
  let(:assembled_result) { JSON.parse(subject.assemble_with(params)) }

  it "merges params with context options" do
    subject.api.should_receive(:compose!).with(params.merge subject.context.options)
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
    subject.api.stub(:compose!) { raise ArgumentError, "my message" }
    assembled_result.should eql "status" => "error", "message" => "my message"
  end

  def build_context
    TheGrid::Builder::Context.new do
      api_key 1234567
      column :name
      column :is_active
    end
  end

end
