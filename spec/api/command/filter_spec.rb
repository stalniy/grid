require 'spec_helper'

shared_examples "for a range filter" do
  let(:filters){ { :field => filter } }

  context "when both boundaries are specified" do
    it "adds 'from' filter" do
      relation.table[:field].should_receive(:gteq).with(value[:from])
    end

    it "adds 'to' filter" do
      relation.table[:field].should_receive(:lteq).with(value[:to])
    end
  end

  context "when left boundary is missed" do
    before(:each){ filter.delete(:from) }

    it "adds 'to' filter" do
      relation.table[:field].should_receive(:lteq).with(value[:to])
    end

    it "does not add 'from' filter" do
      relation.table[:field].should_not_receive(:gteq)
    end
  end

  context "when right boundary is missed" do
    before(:each){ filter.delete(:to) }

    it "adds 'from' filter " do
      relation.table[:field].should_receive(:gteq).with(value[:from])
    end

    it "does not add 'to' filter" do
      relation.table[:field].should_not_receive(:lteq)
    end
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
    let(:filter) { {:from => '2013-02-12 12:20:21', :to => '2013-05-12 13:20:01', :type => :date } }
    let(:value)  { Hash[filter.except(:type).map{ |k, v| [k, v.to_time] }] }
    include_examples "for a range filter"
  end

  context "when filters with time range" do
    let(:filter) { {:from => 2.days.ago.to_f, :to => Time.now.to_f, :type => :time } }
    let(:value)  { Hash[filter.except(:type).map{ |k, v| [k, Time.at(v)] }] }
    include_examples "for a range filter"
  end

  context "when filters with non-date range" do
    let(:filter) { {:from => 10, :to => 20} }
    let(:value)  { filter }
    include_examples "for a range filter"
  end

end
