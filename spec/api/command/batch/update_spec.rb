require 'spec_helper'

describe Grid::Api::Command::Batch::Update do
  let(:table)    { double(:primary_key => double(:name => 'id').as_null_object) }
  let(:relation) { double(:table => table).tap{ |r| r.stub(:scoped => r, :where => r) } }

  it "raise exception when items is blank" do
    expect{
      subject.execute_on(relation, :items => [])
    }.to raise_error ArgumentError
  end

  context "when items is present" do
    let(:non_valid_items) { 2.times.map{ |i| {'id' => "string_#{i}", 'name' => "test_#{i}"} } }
    let(:valid_items)     { 4.times.map{ |i| {'id' => i +1 , 'name' => "test_#{i}"} } }
    let(:valid_ids) { valid_items.map{ |r| r['id'] } }
    let(:records)   { valid_items.map{ |r| double(r.merge :update_attributes => true) } }

    before(:each) { relation.stub(:where => records) }
    after(:each)  { subject.execute_on(relation, :items => valid_items + non_valid_items) }

    it "remove items based on by primary key" do
      relation.table.primary_key.should_receive(:in)
    end

    it "reject items with non-integer ids" do
      relation.table.primary_key.should_receive(:in).with(valid_ids)
    end

    it "remove only records with specified ids" do
      relation.should_receive(:where).with(table.primary_key.in(valid_ids))
    end

    it "update attributes with given data" do
      rows = records.index_by(&:id)
      valid_items.each{ |data| rows.fetch(data['id']).should_receive(:update_attributes).with(data.except('id'))  }
    end
  end

end
