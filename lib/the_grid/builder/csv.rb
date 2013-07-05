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
        csv << read_titles_from(context)
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
      context.assemble(options[:with]).each{ |row| options[:to] << row.values }
    end

    def read_titles_from(context)
      context.options[:titles] || context.columns.keys.map{ |col| col.to_s.titleize }
    end

  end
end
