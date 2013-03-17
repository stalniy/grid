Yet Another Grid
=========

This plugin is designed to provide API to build ActiveRecord::Relation and to return
specified information in json format. So, it makes easy to return information from database
and display it using JavaScript MV* based frameworks such as Knockout, Backbone, Angular, etc.

## Template Builder

For Rails based application there is a template builder which makes all the stuff transparant.
Example: app/views/articles/index.json.grid_builder

    grid_for @articles, :per_page => 2 do
      column :title
      column :description
      column(:created_at){ |r| r.created_at.to_s(:date) }
      column :is_published
    end

This produces the next json response:

    {
      "max_page": 3,
      "items": [
        {
          "title": "My test article",
          "description": "Something interesting",
          "created_at": "03/17/2013",
          "is_published": true
        },
        {
          "title": "My hidden article",
          "description": "Something not interesting",
          "created_at": "03/16/2013",
          "is_published": false
        }
      ]
    }


## API

API is based on commands, so each command can execute any operation on any ActiveRecord::Relation.
There are few predefined commands: `paginate, search, sort, filter, batch/update, batch/remove`

To retrieve data client has to send GET request with the following parameters:
- *cmd*: list of commands which should be applied (optional, by default uses `paginate`)
- *query*: search query (required for `search` command)
- *field*: specifies by which column information should be sorted (required for `sort` command)
- *order*: specifies sort order (optional for `sort` command, by default `asc`)
- *filters*: hash of filters (required for `filter` command). Examples:
    - `{ :name => "test" }` => `name LIKE "%test%"`
    - `{ :created_at => { :from => ... , :to => ... } }` => `created_at >= :from AND created_at <= :to`
      from/to should be timestamps or dates which can be parsed with Date::DATE_FORMATS[:date] format
    - `{ :id => [1, 2, 3] }` => `id IN (1,2,3)`
- *per_page*: specifies number of items for one page of data (optional by default 10)

Example: # TODO: there should be example of url

#### Grid builder do not respond to batch commands

Batch commands can't be processed with Grid::Builder. So, if there is a need to run batch command use the following syntax:

    Grid.build_for(@articles).run_command!('batch/update', :items => params[:articles])

`run_command!` method may raise exception `Grid::Api::MessageError` if array of items is empty or there is missed or not integer 'id' field.
Each batch command return an array of processed records, so it's possible to build response:

    records = Grid.build_for(@articles).run_command!('batch/update', :items => params[:articles])
    response = { :status => :success, :message => "Articles has been successfully updated"}
    response[:message] = recors.select(&:invalid?).map{ |r| r.errors.full_messages }.join(". ") if records.any?(&:invalid?)
    render :json => response

So, *update* command requires only one parameter "items" - an array of hashes, each hash should have integer value with key 'id'.
*remove* command requires one parameter "item_ids" - an array of integers

It's also possible to get information about columns and/or to add meta data in response.
To get this information client should add *with_meta=1* into GET parameters.
Example: # TODO: url

    grid_for @articles, :per_page => 2 do
      searchable_columns :title
      editable_columns   :title

      # specify any kind of meta parameter
      server_time Time.now

      column :title
      column(:created_at){ |r| r.created_at.to_s(:date) }
    end

This example produces json:
    {
      "meta": {
        "server_time": "2013-03-17 02:11:05 +0200"
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


