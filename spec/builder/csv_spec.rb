require 'spec_helper'
require_relative 'view_builder_helper'

describe TheGrid::Builder::Csv do
  subject{ TheGrid::Builder::Csv.new(records, build_context) }

  include_examples "for Grid View Builder"
  before(:each) { subject.api.stub(:compose!){ subject.api.options[:max_page] = 25 } }

  let(:record)  {{ :id => 1, :name => "Name", :status => "Active", :text => "Text" }}
  let(:records) {[ record, record, record ]}
  let(:params)  {{ :cmd => [:sort], :field => :name, :order => :desc, :per_page => 10 }}

  it "generates expected csv string" do
    subject.assemble_with(params).should eql generate_csv(records, subject.context.options[:headers])
  end

  it "uses titleized column names if headers are not specified" do
    subject.context.stub(:options => {})
    headers = record.keys.map{|c| c.to_s.titleize }
    subject.assemble_with(params).should eql generate_csv(records, headers)
  end


  def generate_csv(records, headers)
    CSV.generate do |csv|
      csv << headers
      records.each{ |item| csv << item.values }
    end
  end

  def build_context
    TheGrid::Builder::Context.new do
      headers "Id", "Title", "Status", "Description"
      column :name
      column :status
      column :text
    end
  end

end
