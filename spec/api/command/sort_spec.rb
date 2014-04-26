require 'spec_helper'

describe TheGrid::Api::Command::Sort do
  let(:relation) { double(:table_name => "table_for_sort", :column_names => %w{id name}) }
  let(:options)  { {:field => "name", :order => "desc" } }

  after(:each){ subject.execute_on(relation, options) }

  it "sort by asc if order invalid" do
    options[:order] = 'wrong order'
    relation.should_receive(:order).with("#{relation.table_name}.#{options[:field]} asc")
  end

  it "sort by specified order" do
    relation.should_receive(:order).with("#{relation.table_name}.#{options[:field]} #{options[:order]}")
  end

  it "does not prepend field with table name if field is an alias" do
    options[:field] = 'title'
    relation.should_receive(:order).with("#{options[:field]} #{options[:order]}")
  end
end
