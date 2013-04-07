require 'spec_helper'

describe Grid::Builder::Context do
  subject{ Grid::Builder::Context }

  let(:options) {{ :per_page => 25, :scope => parent_scope }}
  let(:parent_scope) { double("ParentScope") }

  context "by default" do
    it "has hidden id column" do
      build_context.columns[:id].should have_key(:hidden)
    end

    it "stores specified options" do
      build_context.options[:per_page].should eql options[:per_page]
    end

    it "requires block" do
      expect{ subject.new(options) }.to raise_error ArgumentError
    end

    it "respects parent context" do
      parent_scope.should_receive(:article_path)
      build_context{ url article_path }
    end
  end

  context "DSL" do
    it "defines columns" do
      build_context{ column :name; column :url }.columns.keys.should include(:name, :url)
    end

    it "specifies column specific options" do
      columns = build_context{ column :name, :test => true, :value => 5 }.columns
      columns[:name].values_at(:test, :value).should eql [true, 5]
    end

    it "marks columns as featurable" do
      columns = build_context{ searchable_columns :name, :text }.columns
      columns[:name][:searchable].should be_true
      columns[:text][:searchable].should be_true
    end

    it "accepts single option's values" do
      options = build_context{ title "test"; email "test@example.com" }.options
      options.values_at(:title, :email).should eql %w{ test test@example.com }
    end

    it "accepts multiple option's values" do
      build_context{ my :name, :age, :pan }.options[:my].should eql [:name, :age, :pan]
    end

    it "accepts column generator" do
      build_context{ column(:name){ "test" } }.columns[:name][:as].should respond_to(:call)
    end

    it "defines nested scope" do
      context = build_context{ scope_for(:articles) { column :title } }
      context.columns[:articles][:as].should be_kind_of subject
    end

    it "defines nested scope with specified name" do
      context = build_context{ scope_for(:articles, :as => :children) { column :title } }
      context.columns[:children][:as].should be_kind_of subject
    end
  end

  context "when collects visible columns" do
    it "returns only visible columns"
    it "respects visible columns of nested scopes"
  end

  def build_context(&dsl)
    dsl = Proc.new{} unless block_given?
    subject.new(options, &dsl)
  end
end