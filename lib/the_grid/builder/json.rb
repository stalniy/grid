module TheGrid
  class Builder::Json
    cattr_accessor :prettify_json
    attr_reader :api, :context

    def initialize(relation, context)
      @api = TheGrid::Api.new(relation)
      @context = context
    end

    def assemble_with(params)
      options = params.merge context.params
      api.compose!(options)
      stringify as_json_with(options)
    rescue ArgumentError => error
      stringify as_json_message('error', error.message)
    end

  private

    def stringify(json_hash)
      self.class.prettify_json ? JSON.pretty_generate(json_hash) : json_hash.to_json
    end

    def as_json_with(options)
      json = {:max_page => api.options[:max_page], :items => context.assemble(api.relation)}
      if options[:with_meta]
        json[:meta] = context.options.except(:delegate, :search_over)
        json[:columns] = columns_as_array(context.visible_columns)
      end
      json
    end

    def as_json_message(status, message)
      {:status => status, :message => message}
    end

    def columns_as_array(columns)
      columns.map do |name, options|
        options[:columns] = columns_as_array(options[:columns]) if options[:columns].is_a? Hash
        options.merge :name => name
      end
    end

  end
end
