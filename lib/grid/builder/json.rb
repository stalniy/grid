module Grid
  class Builder::Json
    cattr_accessor :prettify_json
    attr_reader :context, :api

    def initialize(relation, context)
      @api = Grid::Api.new(relation)
      @context = context
      apply_api_context
    end

    def assemble_with(params)
      options = configure(params.merge context.options)
      api.build_with!(options)
      stringify json_api(options)
    rescue ::Grid::Api::MessageError => e
      stringify json_api_message(e)
    end

    def assemble
      api.build_with!(context.options) if context.options[:cmd].respond_to?(:each)
      as_json
    end

    def stringify(json_hash)
      self.class.prettify_json ? JSON.pretty_generate(json_hash) : json_hash.to_json
    end

  private

    def json_api(options)
      {}.tap do |json|
        json[:meta], json[:columns] = context.options, context.visible_columns if options[:with_meta]
        json[:max_page] = api.max_page(:per_page => options[:per_page]) unless options[:per_page] === false
        json[:items] = as_json
      end
    end

    def json_api_message(notice)
      {:status => notice.status, :message => notice.message}
    end

    def as_json
      api.relation.map{ |record| build_row_for(record) }
    end

    def build_row_for(record)
      context.columns.inject({}) do |row, column|
        row[column.first] = build_column_for(record, column.first, column.last)
        row
      end
    end

    def build_column_for(record, name, options)
      formatter = options[:as]

      if formatter.respond_to?(:call)
        formatter.call(record)
      elsif formatter.is_a? Symbol
        record.send(formatter)
      elsif formatter.is_a? Builder::Context
        self.class.new(record.send(formatter.name), formatter).assemble if can_use_scope_for?(record, name, options)
      else
        record.send(name)
      end
    end

    def configure(params)
      params.tap do |o|
        o[:cmd] = Array.wrap(o[:cmd])
        o[:cmd].unshift('paginate') unless params[:per_page] === false
        o[:cmd].uniq!
        o[:searchable_columns] = context.column_names_marked_as(:searchable)
      end
    end

    def apply_api_context
      api.delegate(context.options.delete(:delegate)) if context.options[:delegate]
    end

    def can_use_scope_for?(record, name, options)
      condition = options[:if] || options[:unless]

      if condition.is_a? Symbol
        result =  build_column_for(record, name, context.columns[condition])
      elsif condition.respond_to?(:call)
        result = condition.call(record)
      else
        result = true
      end
      options[:unless].present? ? !result : result
    end
  end
end