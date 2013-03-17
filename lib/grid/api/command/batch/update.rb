module Grid
  class Api::Command::Batch::Update < Api::Command::Batch
    def configure(relation, params)
      super.tap do |params|
        raise BadContext, "There is nothing to update" if params[:items].blank?
      end
    end

    def run_on(relation, params)
      record_ids = params[:items].map{ |row| row['id'] }
      records = relation.where(:id => record_ids).index_by(&:id)

      params[:items].map do |row|
        record = records[row['id'].to_i]
        record.tap{ |r| r.update_attributes(row.except('id')) } unless record.nil?
      end.compact
    end

  end
end