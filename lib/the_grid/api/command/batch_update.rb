module TheGrid
  class Api::Command::BatchUpdate < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:items] = params.fetch(:items, []).reject{ |item| item['id'].to_i <= 0 }
        raise ArgumentError, "There is nothing to update" if o[:items].blank?
      end
    end

    def run_on(relation, params)
      record_ids = params[:items].map{ |row| row['id'] }
      primary_key = relation.scoped.table.primary_key
      records = relation.where(primary_key.in(record_ids)).index_by(&primary_key.name.to_sym)

      params[:items].map do |row|
        record = records[row['id'].to_i]
        record.tap{ |r| r.update_attributes(row.except('id')) } unless record.nil?
      end.compact
    end
  end
end
