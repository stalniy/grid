require 'csv'

module TheGrid
  class Builder::Csv
    attr_reader :api, :context

    BATCH_SIZE = 1000

    def initialize(relation, context)
      @api = TheGrid::Api.new(relation)
      @context = context
    end

    def assemble_with(params)
      options = params.merge context.params
      api.compose!(options.reverse_merge! :per_page => false)
      rows = need_batch?(options) ? generate_rows_lazy_for(api.relation) : generate_rows_for(api.relation)
      generate_csv_for rows
    end

  private


    def generate_csv_for(rows)
      CSV.generate do |csv|
        csv << headers
        rows.each { |row| csv << row }
      end
    end

    def generate_rows_lazy_for(relation)
      batch_offset = 0
      relation = api.relation.limit(BATCH_SIZE)
      records = relation.all

      rows = []
      while relation.any?
        rows << context.assemble(relation).map(&:values)
        batch_offset += BATCH_SIZE
        relation.offset(batch_offset)
      end
      rows
    end

    def generate_rows_for(relation)
      context.assemble(relation).map(&:values)
    end

    def headers
      context.options[:headers] || context.columns.keys.map { |col| col.to_s.titleize }
    end

    def need_batch?(options)
      options[:per_page] === false
    end

  end
end
