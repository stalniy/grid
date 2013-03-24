require 'spec_helper'

describe Grid::Api::Command::BatchRemove do
  let(:table)    { double(:primary_key => double.as_null_object) }
  let(:relation) { double(:table => table).tap{ |r| r.stub(:scoped => r, :where => r) } }

  it "raise exception when item_ids is blank" do
    expect{
      subject.execute_on(relation, :item_ids => [])
    }.to raise_error ArgumentError
  end

  it "is a batch command" do
    subject.batch?.should be_true
  end

  context "when item_ids is present" do
    let(:item_ids) { [1, 2, 'non-int', 3, 4, '5'] }
    let(:int_ids)  { item_ids.reject{ |id| id.to_i <= 0 } }

    before(:each) { relation.stub(:destroy_all => int_ids) }
    after(:each)  { subject.execute_on(relation, :item_ids => item_ids) }

    it "remove items based on by primary key" do
      relation.table.primary_key.should_receive(:in)
    end

    it "reject non-integer ids" do
      relation.table.primary_key.should_receive(:in).with(int_ids)
    end

    it "remove only records with specified ids" do
      relation.should_receive(:where).with(table.primary_key.in(int_ids))
    end

    it "destroy records" do
      relation.should_receive(:destroy_all)
    end
  end

end
