require 'spec_helper'

describe Grid::Api::Command::Paginate do
  let(:relation){ double("ActiveRecord::Relation").as_null_object }

  context "when options are missed" do
    after(:each){ subject.execute_on(relation, {}) }

    it "returns first page" do
      relation.should_receive(:offset).with(0)
    end

    it "returns default amount of items" do
      relation.should_receive(:limit).with(subject.class.default_per_page)
    end
  end

  context "when options are specified" do
    after(:each){ subject.execute_on(relation, :page => 3, :per_page => 5) }

    it "returns specified page" do
      relation.should_receive(:offset).with(10)
    end

    it "returns specified amount of items" do
      relation.should_receive(:limit).with(5)
    end
  end

  context "when prepares context" do
    let(:api) { double("Grid::Api", :relation => double(:count => 25).as_null_object, :options => {}) }
    before(:each) { subject.prepare_context(api, :page => 1, :per_page => 15) }

    it "calculates max_page" do
      api.options[:max_page].should eql 2
    end
  end

  context "when calculates max page" do
    before(:each){ relation.stub(:count => 25) }

    it "should use default per_page option" do
      subject.calculate_max_page_for(relation, {}).should eql (25.0 / subject.class.default_per_page).ceil
    end

    it "should respect specified per_page option" do
      subject.calculate_max_page_for(relation, :per_page => 15).should eql 2
    end
  end

end