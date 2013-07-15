require 'spec_helper'
require_relative 'view_builder_helper'

describe TheGrid::Builder::Csv do
  subject{ TheGrid::Builder::Csv }

  include_examples "for Grid View Builder"

  let(:api_options) {{ :max_page => 1 }}
  let(:context)  { build_context }
  let(:relation) { double(:connection => double.as_null_object).as_null_object }
  let(:params)   {{ :cmd => [:sort], :field => :name, :order => :desc, :per_page => subject.const_get("BATCH_SIZE") }}

  it "generates expected csv string" do
    subject.assemble(context, :on => relation, :with => params).should eql generate_csv(records, context.column_titles)
  end

  it "uses titleized column names if titles are not specified" do
    context.stub(:options => {})
    subject.assemble(context, :on => relation, :with => params).should eql generate_csv(records, context.column_titles)
  end

  it "generates csv records in batches" do
    TheGrid::Api.any_instance.should_receive(:run_command!).with(:paginate, :page => 1, :per_page => params[:per_page], :size => api_options[:max_page] * params[:per_page])
    subject.assemble(context, :on => relation, :with => params)
  end

  it "generates csv with nested data" do
    context.stub(:assemble => [ record.merge(:children => [ child_record(1), child_record(2) ]) ])
    subject.assemble(context, :on => relation, :with => params).should eql generate_csv(2.times.map{ |i| record.merge child_record(i + 1) }, context.column_titles)
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

      scope_for :children do
        column :name
      end
    end
  end

end
