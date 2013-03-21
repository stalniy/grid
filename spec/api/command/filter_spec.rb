require 'spec_helper'
require 'active_record'

describe Grid::Api::Command::Filter do
  let(:relation){ ActiveRecord::Relation.new double.as_null_object, :table_name }

  context "when filters are missed" do
    after(:each) { subject.execute_on(relation, {}) }

    it "returns the same relation object" do
      relation.should_not_receive(:where)
    end
  end

  context "when filters are specified" do
    # pending
  end
end