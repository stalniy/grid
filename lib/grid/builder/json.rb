module Grid
  class Builder::Json
    cattr_accessor :prettify_json
    attr_reader :api, :context

    def initialize(relation, context)
      @api = Grid::Api.new(relation)
      @context = context
      apply_api_context
    end

    def assemble_with(params)
      options = configure(params.merge context.options)
      api.build_with!(options)
      stringify as_json_with(options)
    rescue ::Grid::Api::MessageError => error
      stringify as_json_message(error)
    end

  private

    def stringify(json_hash)
      self.class.prettify_json ? JSON.pretty_generate(json_hash) : json_hash.to_json
    end

    def as_json_with(options)
      {}.tap do |json|
        json[:meta], json[:columns] = context.options.except(:delegate, :search_over), context.visible_columns if options[:with_meta]
        json[:max_page] = api.options[:max_page] unless options[:per_page] === false
        json[:items] = context.convert(api.relation)
      end
    end

    def as_json_message(notice)
      {:status => notice.status, :message => notice.message}
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
      api.delegate(context.options[:delegate]) if context.options[:delegate]
    end
  end
end
