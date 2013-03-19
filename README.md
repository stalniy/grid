Yet Another Grid
=========

# !!! Under QA !!!

This plugin is designed to provide API for building json response based on `ActiveRecord::Relation` objects.
It makes much easier to fetch information from database for displaying it using JavaScript MV* based frameworks such as Knockout, Backbone, Angular, etc.

## Getting started

First of all specify grid in your Gemfile and run `bundle install`.
After gem is installed you need to run `rails generate grid:install`. This will generate grid initializer file with basic configuration.

## Usage

Controller: 
```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  respond_to :json

  def index
    @articles = Article.published
    respond_with @articles
  end
end
```

View:
```ruby
# app/views/articles/index.json.grid_builder
grid_for @articles :per_page => 25 do
  searchable_columns :title

  column :title
  column(:created_at){ |r| r.created_at.to_s(:date) }
  column(:author){ |r| r.aurhor.full_name }
end
```

## API

The API is based on commands. Term *command* describes client's action which can be simple or complicated as well.
The general request looks like:

    http://your.domain.com/route.json? with_meta=1 &
      page=1 &
      cmd[]=sort & field=title & order=desc &
      cmd[]=search & query=test &
      cmd[]=filter & filters[created_at][from]=1363513288 & filters[created_at][to]=1363513288

Each parameter relates to options of a command. The only exception is **with_meta** parameter which is used to retrieve extra meta information of grid.

### Commands

There are 2 types of commands: batch commands (e.g. *update, remove*) and select commands (e.g. *search*, *paginate*, *sort*, *filter*).
Select commands can be processed per one request (i.e. stacked) by **Grid::Builder** (method `execute_on` of such commands always returns `ActiveRecord::Relation`).
Batch commands can't be processed by **Grid::Builder** even more they are ignored (method `execute_on` returns array of processed records or boolean value).
There are few predefined commands: `paginate`, `search`, `sort`, `filter`, `batch/update`, `batch/remove`.

#### Paginate

This command has 2 non-required parameters:

- **page** specifies page of data (integer number, starts with 1)
- **per_page** specifies how much records should be selected per one page (integer number)

#### Sort

This command has also 2 paramters:

- **field** specifies sort column (string)
- **order** specifies sort order (*asc* or *desc*)

#### Filter

This command requires only one hash parameter **filters** but it can be in 3 different forms:

- `{ :title => "test" }` => `name LIKE "%test%"`
- `{ :created_at => { :from => ... , :to => ..., :type => "time|date|nil" } }` => `created_at >= :from AND created_at <= :to`
    
    - *type* specifies type of from/to parameters (optional, can be *date* or *time*). If `:type` is *date* from/to fields will be parsed as dates with format `Date::DATE_FORMATS[:date]`. If `:type` is *time* from/to fields should be timestamps.
    - *from/to* specifies top and bottom limits (one of them can be omitted)

- `{ :id => [1, 2, 3] }` => `id IN (1,2,3)`

#### Search

This command requires only one parameter **query** which specifies search string.

#### Batch/Update

This command requires one parameter **items** - an array of hashes (with stringified keys).
Each hash should contain integer value with key *id*. Hash row is ignored if *id* is omitted or non-integer.

#### Batch/Remove

This command also requires one parameter **item_ids** - array of integer ids.
Value of array is ignored if it's non-integer.

### Run batch commands

It's impossible to run batch commands using `Grid::Builder`. So, client has to manually build grid instance and call `run_command!` method:
```ruby
    Grid.build_for(Article).run_command!('batch/update', params)
```
Actually it's possible to run any command as shown in line above.
Example of controller's batch action:
```ruby
class ArticlesController < ApplicationController
  def batch_update
    articles = Grid.build_for(Article).run_command!('batch/update', :items => params[:articles])
    render :json => build_grid_response_for(articles, :success => "Articles has been successfully updated")
  rescue Grid::Api::MessageError => e
    render :json => { :message => e.message, :status => :error }
  end

private
  def build_grid_response_for(records, options = {})
    error_message = records.select(&:invalid?).map{ |r| r.errors.full_messages }.join('. ')
    if error_message.blank?
      {:status => :success, :message => options[:success]}
    else
      {:status => :error, :message => error_message}
    end
  end
 end
```
### Create/override commands

It's a normal situation when client needs a custom command or a custom version of existing command.
Suppose there is a need in `suspend` command which change status of records into *suspended*.
Command class should implement at least  2 methods: `configure` and `run_on`.
`configure` method should return validated parameters or raise an error if one of the required options is missed. Example:
```ruby
module GridCommands
  class Batch
  
    class Suspend < Grid::Api::Command::Batch
      def configure(relation, params)
        super.tap do |o|
          raise Grid::Api::Command::BadContext, "There is nothing to update" if o[:item_ids].blank?
        end
      end

      def run_on(relation, params)
        relation.where(relation.table.primary_key.in(params[:item_ids])).update_all(:status => 'suspended')
      end
    end
    
  end
end
```
For running this command it's also necessarely to update `commands_lookup_scopes`. It can be done inside grid intializer file:
```ruby
# config/initializers/grid.rb
Grid.configure do |config|
  # Specifies scopes for custom commands
  config.commands_lookup_scopes += %w{ grid_commands }
  # ....
end
```
Then it will be possible to run:
```ruby
Grid.build_for(Article).run_command!('batch/suspend', :item_ids => params[:id])
```
Using lookup technique it's possible to override existing commands. Suppose there is a need to customize `batch/update` command to allow non-integer ids:
```ruby
module GridCommands
  class Batch

    class Update < Grid::Api::Command::Batch::Update
      def configure(relation, params)
        {}.tap do |o|
          o[:item_ids] = params[:item_ids].reject(&:blank?)
          raise Grid::Api::Command::BadContext, "There is nothing to update" if o[:item_ids].blank?
        end
      end
    end
    
  end
end
```

## Template Builder

For Rails based application there is a template builder which does all the stuff under the hood.
```ruby
# app/views/articles/index.json.grid_builder
grid_for @articles, :per_page => 2 do
  column :title
  column :description
end
```
Such view is converted into the next json response:
```json
{
  "max_page": 3,
  "items": [
    {
      "id": 1,
      "title": "My test article",
      "description": "Something interesting"
    },
    {
      "id": 2,
      "title": "My hidden article",
      "description": "Something not interesting"
    }
  ]
}
```
It's possible to format column output by passing block into column declaration:
```ruby
# app/views/articles/index.json.grid_builder
grid_for @articles, :per_page => 2 do
  column :title
  column :description
  column(:created_at){ |article| article.created_at.to_s(:date) }
end
```
Also it's possible to specify extra information for each column (e.g. *editable*, *searchable*, etc):
```ruby
# app/views/articles/index.json.grid_builder
grid_for @articles, :per_page => 2 do
  column :title, :editable => true, :sortable => true, :an_option => "any extra information"
  column :description, :editable => true
  column(:created_at, :editable => true){ |article| article.created_at.to_s(:date) }
end
```
Looks like a mess, don't it? However there are helper's methods which helps to clean up this view:
```ruby
# app/views/articles/index.json.grid_builder
grid_for @articles, :per_page => 2 do
  editable_columns :title, :description, :created_at
  sortable_columns :title

  column :title, :an_option => "any extra information"
  column :description
  column(:created_at){ |article| article.created_at.to_s(:date) }
end
```
It's possible to specify any features for columns using the next DSL method template: `"#{feature}ble_columns"` (e.g. `visible_columns *columns_list`).
`searchable_columns` method is a bit special. It not only marks column with searchable flag but also specifies which columns will be searched when `search` command is run.

Sometimes it's reasonable to add extra meta information into response:
```ruby
grid_for @articles, :per_page => 2 do
  searchable_columns :title, :created_at

  # specify any kind of meta parameter
  server_time Time.now
  my_option   "Something important for Frontend side"

  column :title
  column(:created_at){ |r| r.created_at.to_s(:date) }
end
```
Columns meta and extra meta information will be accessible in response only if client specifies non-empty **with_meta** parameter in request.
The previous example is converted into:
```json
{
  "meta": {
    "server_time": "2013-03-17 02:11:05 +0200",
    "my_option": "Something important for Frontend side"
  },
  "columns": {
    "title": {
      "searchable": true,
      "editable": true
    },
    "created_at": {
      "searchable": true
    }
  },
  "max_page": 3,
  "items": [
    {
      "id": 1,
      "title": "My test article",
      "created_at": "03/17/2013"
    },
    {
      "id": 2,
      "title": "My hidden article",
      "created_at": "03/16/2013"
    }
  ]
}
```
`per_page` option can be omitted. In such cases will be used `params[:per_page]` or default per page value specified inside grid initializer.
Sometimes client need to retrieve all records without pagination. So, for disabling pagination just set `per_page` option to `false`. In such cases `max_page` will be omitted in response.

#### Nested scopes and tree-like structures

If you need to create tree-like stucture for custom grid view (e.g. complex navigation) you can use `scope_for` declaration:
```ruby
grid_for @groups, :per_page => 2 do
  column :name
  column :is_active do |p|
    params[:current_id].to_i == p.id
  end
  
  scope_for :articles do
    column :title
    column :created_at do |a|
      a.created_at.to_s(:date)
    end
  end
end
```
This example builds the next response:
```json
{
  "max_page": 2,
  "items": [
    {
      "id": 1,
      "name": "test",
      "is_active": true,
      "articles": [
        {
          "id": 2,
          "title": "Something inetresting",
          "created_at": "03/17/2013"
        },
        {
          "id": 4,
          "title": "test article",
          "created_at": "03/14/2013"
        }
      ]
    },
    {
      "id": 3,
      "name": "test2",
      "is_active": false,
      "articles": [
        {
          "id": 3,
          "title": "test article 2",
          "created_at": "03/13/2013"
        }
      ]
    }
  ]
}
```
If you need to standardize output you can specify `:as` option - the column name for nested grid (e.g. if you specify `:as => :children` then *articles* key will be substituted with *children* key).
Also there are 2 conditional options `:unless` and `:if` which accepts lambda or symbol.
If you specify symbol as condition will be used column value with such name (in this case it's important that column is defined before scope).
If you need some custom logic to detect if scope should be created for such row or not you can pass lambda.

For example we want to get articles only of active/current group:
```ruby
grid_for @groups, :per_page => 2 do
  column :name
  column :is_active do |p|
    params[:current_id].to_i == p.id
  end
  
  scope_for :articles, :as => :children, :if => :is_active do
    column :title
  end
end
```
Or the same with lambda:
```ruby
grid_for @groups, :per_page => 2 do
  column :name
  column :is_active do |p|
    params[:current_id].to_i == p.id
  end
  
  scope_for :articles, :as => :children, :if => lambda{ |group| group.id == params[:current_id].to_i } do
    column :title
  end
end
```
This produces the response:
```json
{
  "max_page": 2,
  "items": [
    {
      "id": 1,
      "name": "test",
      "is_active": true,
      "children": [
        {
          "id": 2,
          "title": "Something inetresting",
          "created_at": "03/17/2013"
        },
        {
          "id": 4,
          "title": "test article",
          "created_at": "03/14/2013"
        }
      ]
    },
    {
      "id": 3,
      "name": "test2",
      "is_active": false,
      "children": null
    }
  ]
}
```
#### Command delegation

Sometimes there is a need to delegate command processing to nested nested grid. For example, there are groups and articles.
You need to display groups sorted by name asc and provide ability to sort articles inside each group by any columns.
For such purposes you can use `delegate` declaration:
```ruby
grid_for @groups, :per_page => 2 do
  delegate :sort => :articles, :filter => :articles

  column :name
  column :is_active do |p|
    params[:current_id].to_i == p.id
  end
  
  scope_for :articles, :as => :children, :if => :is_active do
    column :title
  end
end
```
## License

Released under the [MIT License](http://www.opensource.org/licenses/MIT)
