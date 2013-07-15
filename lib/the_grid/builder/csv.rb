require 'csv'

module TheGrid
  module Builder::Csv
    extend self, Builder::Base
    BATCH_SIZE = 1000

    def build(context, options)
      records, params = options.values_at(:for, :with)
      options.merge! :per_page => BATCH_SIZE if records.respond_to?(:connection)
      api = compose(records, options)
      CSV.generate do |csv|
        csv << context.column_titles
        api.relation.respond_to?(:connection) ? put(context, :to => csv, :with => api) : put_this(context, :to => csv, :with => records)
      end
    end

  private

    def put(context, options)
      api, csv = options.values_at(:with, :to)
      pages = api.options[:max_page]
      (1..pages).each do |page|
        relation = api.run_command!(:paginate, :page => page, :per_page => BATCH_SIZE, :size => pages * BATCH_SIZE)
        put_this(context, :to => csv, :with => relation)
      end
    end

    def put_this(context, options)
      context.assemble(options[:with]).each do |row|
        flatten(row).each{ |row| options[:to] << row }
      end
    end

    def flatten(row)
      # TODO: optimize it
      row_values, row_nested_values = [], []
      row.each do |field, value|
        if value.kind_of?(Array)
          row_nested_values += value.flat_map{ |r| flatten(r) }
        else
          row_values << value 
        end
      end
      return [ row_values ] if row_nested_values.empty?
      row_nested_values.each{ |nested_values| nested_values.unshift(*row_values) }
    end

  end
end
