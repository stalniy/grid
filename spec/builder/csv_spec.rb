require 'spec_helper'

describe TheGrid::Builder::Csv do
  let(:relation) { double('Relation') }
  let(:record) {{:name => "Name", :is_active => "Active", :description => "Descr"}}
  let(:records) { [record, record, record] }

  it "merges params with context options" do
    context = build_context { column :name }
    subject = build_subject(context)
    subject.api.should_receive(:compose!).with(context.options)
    subject.assemble_with({})
  end

  it "generates csv" do
    context = build_context do
      headers "Name", "Status", "Short description"

      column :name
      column :is_active
      column :description
    end
    subject = build_subject(context)
    subject.assemble_with({}).should eql generate_csv(records, context.options[:headers])
  end

  it "titleizes column names if 'headers' not specified" do
    context = build_context do
      column :name
      column :is_active
      column :description
    end
    subject = build_subject(context)
    titleized_headers = context.visible_columns.keys.map {|c| c.to_s.titleize }
    subject.assemble_with({}).should eql generate_csv(records, titleized_headers)
  end

  def generate_csv(records, headers)
    CSV.generate do |csv|
      csv << headers
      records.each { |item| csv << item.values }
    end
  end

  def build_context(&dsl)
    TheGrid::Builder::Context.new(&dsl).tap{ |c| c.stub(:assemble => records) }
  end

  def build_subject(context)
    TheGrid::Builder::Csv.new(relation, context).tap { |b| b.api.stub(:compose!) }
  end

end
