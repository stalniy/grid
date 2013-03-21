require 'spec_helper'

shared_examples "for a range filter" do
  let(:filters){ { :field => value } }

  context "when both boundaries are specified" do
    it "adds 'from' filter" do
      relation.table[:field].should_receive(:gteq).with(filter[:from])
    end

    it "adds 'to' filter" do
      relation.table[:field].should_receive(:lteq).with(filter[:to])
    end
  end

  it "adds only 'to' filter when left boundary is missed" do
    value.delete(:from)
    relation.table[:field].should_not_receive(:gteq)
    relation.table[:field].should_receive(:lteq).with(filter[:to])
  end

  it "adds only 'from' filter when right boundary is missed" do
    value.delete(:to)
    relation.table[:field].should_not_receive(:lteq)
    relation.table[:field].should_receive(:gteq).with(filter[:from])
  end
end

describe Grid::Api::Command::Filter do
  let(:table)    { double(:blank? => false).as_null_object }
  let(:relation) { double(:table => table).tap{ |r| r.stub(:where => r) } }

  after(:each) { subject.execute_on(relation, :filters => filters) }

  context "when filters are missed" do
    let(:filters){ Hash.new }

    it "returns the same relation object" do
      relation.should_not_receive(:where)
    end
  end

  context "when filters with primary values" do
    let(:filters){ { :id => [1, 2], :state => "test" } }

    it "changes relation conditions" do
      relation.should_receive(:where)
    end

    it "filters by array of values" do
      relation.table[:id].should_receive(:in).with(filters[:id])
    end

    it "filters by value" do
      relation.table[:state].should_receive(:eq).with(filters[:state])
    end
  end

  context "when filters with date range" do
    let(:value)  { {:from => '2013-02-12 12:20:21', :to => '2013-05-12 13:20:01', :type => :date } }
    let(:filter) { Hash[value.except(:type).map{ |k, v| [k, v.to_time] }] }
    include_examples "for a range filter"
  end

  context "when filters with time range" do
    let(:value)  { {:from => 2.days.ago.to_f, :to => Time.now.to_f, :type => :time } }
    let(:filter) { Hash[value.except(:type).map{ |k, v| [k, Time.at(v)] }] }
    include_examples "for a range filter"
  end

  context "when filters with non-date range" do
    let(:value){ {:from => 10, :to => 20} }
    let(:filter) { value }
    include_examples "for a range filter"
  end

end
