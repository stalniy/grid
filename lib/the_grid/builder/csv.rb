require 'csv'

module TheGrid
  class Builder::Csv
    attr_reader :api, :context

    def initialize(relation, context)
      @api = TheGrid::Api.new(relation)
      @context = context
    end

    def assemble_with(params)
      options = params.merge context.options
      api.compose!(options)
      generate_csv
    end

  private

    def generate_csv
      CSV.generate do |csv|
        csv << headers
        context.assemble(api.relation).each { |item| csv << item.values }
      end
    end

    def headers
      context.options[:headers] || context.columns.keys.map { |col| col.to_s.titleize }
    end

  end
end
