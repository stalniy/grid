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
      api.compose!(options.reverse_merge :per_page => false)
      generate_csv_with(options)
    end

  private

    def generate_csv_with(options)
      CSV.generate do |csv|
        csv << headers
        if options.has_key?(:per_page)
          put_rows_to(csv, api.relation.all)
        else
          put_relation_to(csv, api.relation)
        end
      end
    end

    def put_relation_to(csv, relation)
      batch_offset = 0
      relation = relation.limit(BATCH_SIZE)
      records = relation.dup.all

      while records.any?
        put_rows_to(csv, records)
        batch_offset += BATCH_SIZE
        records = relation.offset(batch_offset).all
      end
    end

    def put_rows_to(csv, records)
      context.assemble(records).each{ |row| csv << row.values }
    end

    def headers
      context.options[:headers] || context.columns.keys.map { |col| col.to_s.titleize }
    end

  end
end
