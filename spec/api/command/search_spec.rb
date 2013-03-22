require 'spec_helper'

describe Grid::Api::Command::Search do
  let(:columns)  {{ :name => string_column, :status => string_column, :id => double(:type => :int) }}
  let(:relation) { double(:columns_hash => columns, :column_names => columns.keys, :table => columns).as_null_object }

  after(:each) { subject.execute_on(relation, options) }

  context "when query or search_over is missed" do
    let(:options) { Hash.new }

    it "does not search if query is missed" do
      relation.should_not_receive(:where)
    end

    it "does not search over nested relations if search_over is missed" do
      relation.should_not_receive(:reflections)
    end
  end

  context "when searchable_columns is missed" do
    let(:options) {{ :query => "test" }}

    it "search over own columns" do
      relation.should_receive(:columns_hash)
    end

    it "does not search over non-string columns" do
      relation.table[:id].should_not_receive(:matches)
    end

    it "combine searchable conditions by or" do
      relation.table[:name].should_receive(:or).with(relation.table[:status])
    end
  end

  context "when options are valid" do
    let(:options) {{ :query => "test", :searchable_columns => [:name] }}

    it "search by query" do
      relation.should_receive(:where)
    end

    it "search only by specified columns" do
      relation.table[:status].should_not_receive(:matches)
      relation.table[:id].should_not_receive(:matches)
    end

    it "search using SQL LIKE" do
      relation.table[:name].should_receive(:matches).with("%#{options[:query]}%")
    end
  end

  context "when search over nested relations" do
    pending "logic is too complicated; maybe will be rewritten"
  end

  def string_column
    double(:type => :string).tap do |c|
      c.stub(:matches => c, :or => c)
    end
  end

end
