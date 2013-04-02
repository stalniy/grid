module Grid
  class Builder::Json
    cattr_accessor :prettify_json
    attr_reader :api, :context

    def initialize(relation, context)
      @api = Grid::Api.new(relation)
      @context = context
    end

    def assemble_with(params)
      options = params.merge context.options
      api.build_with!(options)
      stringify as_json_with(options)
    rescue ArgumentError => error
      stringify as_json_message('error', error.message)
    end

  private

    def stringify(json_hash)
      self.class.prettify_json ? JSON.pretty_generate(json_hash) : json_hash.to_json
    end

    def as_json_with(options)
      {}.tap do |json|
        json[:meta], json[:columns] = context.options.except(:delegate, :search_over), context.visible_columns if options[:with_meta]
        json[:max_page] = api.options[:max_page]
        json[:items] = context.assemble(api.relation)
      end
    end

    def as_json_message(status, message)
      {:status => status, :message => message}
    end
  end
end
