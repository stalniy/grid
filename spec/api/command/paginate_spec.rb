require 'spec_helper'

describe Grid::Api::Command::Paginate do
  let(:relation){ double("ActiveRecord::Relation") }

  context "when executes" do
    it "should use default options" do
      relation.should_receive(:limit).with(subject.class.default_per_page).and_return(relation)
      relation.should_receive(:offset).with(0).and_return(relation)

      subject.execute_on(relation, {})
    end

    it "should respect specified options" do
      relation.should_receive(:limit).with(5).and_return(relation)
      relation.should_receive(:offset).with(10).and_return(relation)

      subject.execute_on(relation, :page => 3, :per_page => 5)
    end
  end

  context "when calculates max page" do
    before(:each) do
      relation.should_receive(:count).and_return(25)
      relation.should_receive(:except).and_return(relation)
    end

    it "should use default per page option" do
      subject.calculate_max_page_for(relation, {}).should eql (25.0 / subject.class.default_per_page).ceil
    end

    it "should respect specified per page option" do
      subject.calculate_max_page_for(relation, :per_page => 15).should eql 2
    end
  end

end