require 'spec_helper'

describe Grid::Builder::Context do 
  let(:context) { create_context(options) }
  let(:scope) { double(:article_path => '/article/1') }
  let(:options) {{:name => :test_grid, :per_page => 25, :scope => scope }}

  context "when initializes" do

    it "has hidden ID column by default" do
      context.columns[:id][:hidden].should be_true
    end

    it "accepts options" do
      context.options[:per_page].should eql 25
    end

    it "requires scope" do
      context.scope.should_not be_nil
    end

    it "evaluates given block from 'grid_for' method"
  end

  context "when evaluates block" do

    it "builds column by name" do
      context.columns.should have_key :title
    end

    it "accepts an arguments for column" do
      context.columns[:title][:sortable].should be_true
    end

    it "accepts block as formatter" do
      context.columns[:title].should have_key :as
    end

    it "uses view helpers" do
      context.options[:my_link].should eql scope.article_path
    end

    it "specifies column-feature oriented helpers like 'searchable_columns'" do
      context.columns[:title][:my_featureble].should be_true
    end

    it "allows to store any meta key-value pairs of information" do
      context.options[:my_option].should eql "My value"
    end

    context "when defines nested grid" do

      it "uses 'scope_for' helper and creates new column" do
        context.columns.should have_key :articles
      end

      it "accepts :as option for standardize nested structure names" do
        context.columns.should have_key :children
      end
    end
  end

  context "when assemble" do
    let(:page) { double(:id => 1, :name => 'Name of page') }
    let(:pages) { (1..2).inject([]) { |pages, n| pages.push page } }
    let(:book) { double(:id => 1, :title => 'Book title') }
    let(:books) { (1..2).inject([]) { |books, n| books.push book } }
    let(:article) { double(:id => 1, :name => 'Article name') }
    let(:articles) { (1..2).inject([]) { |articles, n| articles.push article } }
    let(:category) { double(:id => 1, :title => 'title of category', :articles => articles, :books => books, :is_published => true, :pages => pages) }
    let(:categories) { [1].inject([]) { |categories, n| categories.push category } }
    let(:json_schema) { [
        {
          :id => 1,
          :title => "Title Of Category",
          :is_published => true,
          :is_active => true,
          :articles => [
            {:id => 1, :name => "Article name"},
            {:id => 1, :name => "Article name"},
          ],
          :children => [
            {:id => 1, :title => "Book title"},
            {:id => 1, :title => "Book title"},
          ],
          :pages => [
            {:id => 1, :name => "Name of page"},
            {:id => 1, :name => "Name of page"},
          ],
        },
      ]
    }

    it "builds an array of hashes" do
      context.assemble(categories).should eql json_schema
    end
  end

  it "defines visible columns" do 
    context.visible_columns.keys.should eql [:title, :is_published, :is_active, :articles, :children, :pages]
  end


  def create_context(options)
    Grid::Builder::Context.new(options) do
      my_option "My value"
      my_featureble_columns :title
      my_link article_path 

      column(:title, :sortable => true) { |category| category.title.titleize }
      column :is_published
      column :is_active, :as => :is_published

      scope_for :articles, :if => :is_published do
        column :name
      end

      scope_for(:books, :as => :children, :unless => lambda { |category| !category.is_published }) do
        column :title
      end

      scope_for :pages do
        column :name
      end
    end
  end

end