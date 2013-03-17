Yet Another Grid
=========

# !!! Under development !!!

This plugin is designed to provide API for building json based on ActiveRecord::Relation objects.
It makes much easier to fetch information from database for displaying it using JavaScript MV* based frameworks such as Knockout, Backbone, Angular, etc.

## API

The API is based on term commands, so each command is like a client action which can do anything with ActiveRecord::Relation.
The general request looks like:

  http://your.domain.com/route.json?**with_meta**=1&**page**=1&**cmd**[]=sort&**field**=title&**order**=desc&**cmd**[]=search&**query**=test&**cmd**[]=filter&**filters**[created_at][from]=1363513288&**filters**[created_at][to]=1363513288

Each parameter (in bold) relates to options of some command. Then only exception is **with_meta** parameter which is used to retrieve extra meta information of grid.

### Commands

There are 2 types of commands: batch commands (e.g. *update, remove*) and stackable commands (e.g. *search*, *paginate*, *sort*, *filter*).
Stackable commands can be processed per one request by **Grid::Builder** (method `execute_on` of such commands returns ActiveRecord::Relation).
Batch commands can't be processed by **Grid::Builder** even more they will be ignored (method `execute_on` returns array of processed records).
There are few predefined commands: `paginate`, `search`, `sort`, `filter`, `batch/update`, `batch/remove`.

#### Paginate

This command can be configured with 2 parameters:

- **page** specifies page of data (integer number, starts with 1)
- **per_page** specifies how much records should be return per on page (integer number)

#### Sort

This command has also 2 paramters:

- **field** specifies which field data should be sorted by (string)
- **order** specifies sort order (*asc* or *desc*)

#### Filter

This command requires only one hash parameter **filters** but it can be in 3 different forms:

- `{ :title => "test" }` => `name LIKE "%test%"`
- `{ :created_at => { :from => ... , :to => ... } }` => `created_at >= :from AND created_at <= :to`;
  *from/to* params should be timestamps or dates which can be parsed with `Date::DATE_FORMATS[:date]` format
- `{ :id => [1, 2, 3] }` => `id IN (1,2,3)`

#### Search

This command requires only one parameter **query** which specifies search string.

#### Batch/Update

This command requires one parameter **items**. This is an array of hashes (with stringified keys).
Each hash should contain integer value with key *id*. Hash row is ignored if *id* is omitted or non-integer.

#### Batch/Remove

This command also requires one parameter **item_ids** - array of integer ids.
Value of array is ignored if it's non-integer.

### Run batch commands

It's possible to run batch command like this:

    class ArticlesController < ApplicationController
     def batch_update
       articles = Grid.build_for(Article).run_command!('batch/update', :items => params[:articles])
       render :json => build_grid_response_for(articles, :success => "Articles has been successfully updated")
     rescue Grid::Api::MessageError => e
       render :json => { :message => e.message, :status => :error }
     end

     def build_grid_response_for(records, options = {})
       error_message = records.select(&:invalid?).map{ |r| r.errors.full_messages }.join('. ')
       if error_message.blank?
         {:status => :success, :message => options[:success]}
       else
         {:status => :error, :message => error_message}
       end
     end
    end

Actually it's possible to run any command like this:

    Grid.build_for(Article).run_command!(command_name, params)

### Create/override commands

Suppose client needs a command which changes status of records to *suspended*.
Each command has usually 2 methods: `configure`, `run_on`; both of them are private.
`configure` method should return validated parameters or raise an error if on of the required is missed.

    module GridCommands
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

To be able to run this command it needed to register this custom scope. This can be done by adding the following line inside grid initializer:

    Grid::Api::Command.register_lookup_scope('grid_commands')

Using lookup scopes it's possible to override existing command inside new scope.
Suppose there is a need to customize `batch/update` command to allow non-integer ids:

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


## Template Builder

For Rails based application there is a template builder which does all the stuff under the hood.

    # app/views/articles/index.json.grid_builder
    grid_for @articles, :per_page => 2 do
      column :title
      column :description
    end

Such view is converted into the next json response:

    {
      "max_page": 3,
      "items": [
        {
          "title": "My test article",
          "description": "Something interesting"
        },
        {
          "title": "My hidden article",
          "description": "Something not interesting"
        }
      ]
    }

It's possible to format column output by passing block into column declaration:

    # app/views/articles/index.json.grid_builder
    grid_for @articles, :per_page => 2 do
      column :title
      column :description
      column(:starts_at){ |article| article.starts_at.to_s(:date) }
    end

Also it's possible to specify any extra information for each column (e.g. *editable*, *searchable*, etc):

    # app/views/articles/index.json.grid_builder
    grid_for @articles, :per_page => 2 do
      column :title, :editable => true, :sortable => true, :an_option => "any extra information"
      column :description, :editable => true
      column(:starts_at, :editable => true){ |article| article.starts_at.to_s(:date) }
    end

Looks like a mess, don't it? However there is a helper methods which can clean up this view:

    # app/views/articles/index.json.grid_builder
    grid_for @articles, :per_page => 2 do
      editable_columns :title, :description, :starts_at
      sortable_columns :title

      column :title, :an_option => "any extra information"
      column :description
      column(:starts_at){ |article| article.starts_at.to_s(:date) }
    end

It's possible to specify any features for columns using the next DSL method template: `"#{feature}ble_columns"` (e.g. `visible_columns *columns_list`).
`searchable_columns` method is a bit special. It not only marks column with searchable flag but also specifies which columns will be searched when `search` command is run.

It's possible not only to add columns meta information but also any kind of meta information:

    grid_for @articles, :per_page => 2 do
      searchable_columns :title, :created_at

      # specify any kind of meta parameter
      server_time Time.now
      my_option   "Something important for Frontend side"

      column :title
      column(:created_at){ |r| r.created_at.to_s(:date) }
    end

Columns meta and extra meta information is accessible in response if client specifies non-empty **with_meta** parameter in request.
The previous example is converted into:

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
          "title": "My test article",
          "created_at": "03/17/2013"
        },
        {
          "title": "My hidden article",
          "created_at": "03/16/2013"
        }
      ]
    }

`per_page` option can be omitted. In such cases will be used `params[:per_page]` or default per page value (10).
It's possible to disable pagination: just set `per_page` option to `false`. In such cases `max_page` will be omitted in response.

#### Nested scopes and tree-like structures

TODO

#### Command delegation

TODO

## License

TODO