require 'spec_helper'
require_relative 'view_builder_helper'

describe TheGrid::Builder::Csv do
  subject{ TheGrid::Builder::Csv.new(relation, build_context) }

  include_examples "for Grid View Builder"
  before(:each) { subject.api.stub(:compose!){ subject.api.options[:max_page] = 1 } }

  let(:relation) { double.as_null_object }
  let(:record)   {{ :id => 1, :name => "Name", :status => "Active", :text => "Text" }}
  let(:records)  {[ record, record, record ]}
  let(:params)   {{ :cmd => [:sort], :field => :name, :order => :desc, :per_page => subject.class.const_get("BATCH_SIZE") }}

  it "generates expected csv string" do
    subject.assemble_with(params).should eql generate_csv(records, subject.context.options[:titles])
  end

  it "uses titleized column names if titles are not specified" do
    subject.context.stub(:options => {})
    titles = record.keys.map{|c| c.to_s.titleize }
    subject.assemble_with(params).should eql generate_csv(records, titles)
  end

  it "generates csv records in batches" do
    subject.api.should_receive(:run_command!).with(:paginate, :page => 1, :per_page => params[:per_page])
    subject.assemble_with(params);
  end


  def generate_csv(records, titles)
    CSV.generate do |csv|
      csv << titles
      records.each{ |item| csv << item.values }
    end
  end

  def build_context
    TheGrid::Builder::Context.new do
      titles "Id", "Title", "Status", "Description"
      column :name
      column :status
      column :text
    end
  end

end
