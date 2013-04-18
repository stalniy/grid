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
      api.compose!(options.merge :per_page => BATCH_SIZE)
      generate_csv_with(options)
    end

  private

    def generate_csv_with(options)
      CSV.generate do |csv|
        csv << headers
        put_relation_to(csv)
      end
    end

    def put_relation_to(csv)
      (1..api.options[:max_page]).each do |page|
        api.run_command!(:paginate, :page => page, :per_page => BATCH_SIZE)
        put_records_to(csv, api.relation.dup)
      end
    end

    def put_records_to(csv, records)
      context.assemble(records).each{ |row| csv << row.values }
    end

    def headers
      context.options[:headers] || context.columns.keys.map { |col| col.to_s.titleize }
    end

  end
end