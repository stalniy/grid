require 'spec_helper'

describe Grid::Api::Command::Sort do
  let(:table)    { double(:name => "table_for_sort", :present? => true).as_null_object }
  let(:relation) { double(:table_name => table.name, :table => table) }
  let(:options)  { {:field => "name", :order => "desc" } }

  after(:each){ subject.execute_on(relation, options) }

  it "sort by asc if order invalid" do
    options[:order] = 'wrong order'
    relation.should_receive(:order).with("#{table.name}.#{options[:field]} asc")
  end

  it "sort by specified order" do
    relation.should_receive(:order).with("#{table.name}.#{options[:field]} #{options[:order]}")
  end

  it "does not prepend field if column is an alias" do
    table.stub(:present? => false)
    relation.should_receive(:order).with("#{options[:field]} #{options[:order]}")
  end
end
