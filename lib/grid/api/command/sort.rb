module Grid
  class Api::Command::Sort < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:field] = params[:field]
        o[:field] = "#{relation.table_name}.#{o[:field]}" unless relation.columns_hash[o[:field]].nil?

        o[:order] = params[:order]
        o[:order] = 'asc' unless %w(asc desc).include?(o[:order])
      end
    end

    def run_on(relation, params)
      relation.order("#{params[:field]} #{params[:order]}")
    end
  end
end