require 'spec_helper'

describe Grid::Builder::Context do
  subject{ Grid::Builder::Context }

  let(:parent_scope) { double(:dsl => Proc.new{ column :title }) }
  let(:options) {{ :per_page => 25, :scope => parent_scope }}

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

    it "responds to assemble" do
      build_context.should respond_to(:assemble).with(1).argument
    end
  end

  context "DSL" do
    it "defines columns" do
      build_context{ column :name; column :url }.columns.keys.should include(:name, :url)
    end

    it "defines column specific options" do
      columns = build_context{ column :name, :test => true, :value => 5 }.columns
      columns[:name].values_at(:test, :value).should eql [true, 5]
    end

    it "marks columns as featurable" do
      columns = build_context{ searchable_columns :name, :text }.columns
      columns.slice(:name, :text).should be_all{ |k, v| v[:searchable] == true }
    end

    it "stores featureable columns in options" do
      build_context{ searchable_columns :name, :text }.options[:searchable_columns].should eql [:name, :text]
    end

    it "accepts single option's values" do
      options = build_context{ title "test"; email "test@example.com" }.options
      options.values_at(:title, :email).should eql %w{ test test@example.com }
    end

    it "accepts multiple option's values" do
      build_context{ my :name, :age, :pan }.options[:my].should eql [:name, :age, :pan]
    end

    it "accepts block as column generator" do
      build_context{ column(:name){ "test" } }.columns[:name][:as].should respond_to(:call)
    end

    it "accepts method_name as column generator" do
      build_context{ column :name, :as => :title}.columns[:name][:as].should eql :title
    end

    it "defines nested scope" do
      context = build_context{ scope_for(:articles, &dsl) }
      context.columns[:articles][:as].should be_kind_of subject
    end

    it "defines nested scope with specified name" do
      context = build_context{ scope_for(:articles, :as => :children, &dsl) }
      context.columns[:children][:as].should be_kind_of subject
    end
  end

  context "when collects visible columns" do
    let(:parent_scope){ double(:dsl => Proc.new{ column :title; column :name, :hidden => true }) }

    it "returns only visible columns" do
      build_context(&parent_scope.dsl).visible_columns.keys.should eql [:title]
    end

    it "respects visible columns of nested scopes" do
      build_context{ scope_for(:children, &dsl) }.visible_columns[:children].keys.should eql [:title]
    end
  end

  context "when assembles" do
    let(:fields)  {{ :title => "item", :id => 5, :live? => false, :short_details => "details" }}
    let(:records) {[ double(fields), double(fields.merge :live? => true) ]}

    context "records" do
      subject { context.assemble(records) }
      let(:context) { build_plane_context }

      it { should be_kind_of Array }
      it { should have(records.size).items }
      it { should be_all{ |r| r.kind_of? Hash } }
      it { should be_all{ |r| r.keys == context.columns.keys }}
    end

    context "any structure" do
      subject{ build_plane_context }
      after(:each){ subject.assemble(records) }

      it "builds records by name" do
        records.each{ |r| r.should_receive(:title) }
      end

      it "builds records by alias" do
        records.each{ |r| r.should_receive(:short_details) }
      end

      it "builds records by given block" do
        records.each{ |r| r.should_receive(:live?) }
      end
    end

    context "tree-like structure" do
      let(:conditional_option) { :if }
      let(:fields) {{ :id => 5, :live? => false, :permanent => [], :conditional => [], :conditional_block => [] }}
      after(:each) { build_tree_like_context(conditional_option).assemble(records) }

      it "creates nested scope for each record" do
        records.each{ |r| r.should_receive(:permanent) }
      end

      context "when specified :if option" do
        it "creates nested scope if record column is true" do
          records.first.should_not_receive(:conditional)
          records.last.should_receive(:conditional)
        end

        it "creates nested scope if block returns true" do
          records.first.should_not_receive(:conditional_block)
          records.last.should_receive(:conditional_block)
        end
      end

      context "when specified :unless option" do
        let(:conditional_option) { :unless }

        it "creates nested :unless block returns true" do
          records.first.should_receive(:conditional)
          records.last.should_not_receive(:conditional)
        end

        it "creates nested :unless block returns true" do
          records.first.should_receive(:conditional_block)
          records.last.should_not_receive(:conditional_block)
        end
      end
    end

    def build_plane_context
      build_context do
        column :title
        column :details, :as => :short_details
        column(:is_active){ |r| r.live? }
      end
    end

    def build_tree_like_context(conditional_option)
      build_context do
        column :is_active, :as => :live?
        scope_for(:permanent, &dsl)
        scope_for(:conditional, conditional_option => :is_active, &dsl)
        scope_for(:conditional_block, conditional_option => proc{ |r| r.live? }, &dsl)
      end
    end

  end

  def build_context(&dsl)
    dsl = Proc.new{} unless block_given?
    Grid::Builder::Context.new(options, &dsl)
  end

end