require 'csv'

module TheGrid
  module Builder::Csv
    extend self, Builder::Base
    BATCH_SIZE = 1000

    def build(context, options)
      records, params = options.values_at(:for, :with)
      params.merge!(:per_page => records.kind_of?(Array) ? false : BATCH_SIZE)
      api = compose(records, params)
      CSV.generate do |csv|
        csv << context.column_titles
        params[:per_page] ? put(context, :to => csv, :with => api) : put_this(context, :to => csv, :with => records)
      end
    end

  private

    def put(context, options)
      api, csv = options.values_at(:with, :to)
      pages = api.options[:max_page]
      (1..pages).each do |page|
        options[:with] = api.run_command!(:paginate, :page => page, :per_page => BATCH_SIZE, :size => pages * BATCH_SIZE)
        put_this(context, options)
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
