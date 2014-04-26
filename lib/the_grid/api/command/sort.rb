module TheGrid
  class Api::Command::Sort < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:field] = params[:field]
        o[:field] = "#{relation.table_name}.#{o[:field]}" if relation.column_names.include?(params[:field])

        o[:order] = params[:order]
        o[:order] = 'asc' unless %w{ asc desc }.include?(o[:order])
      end
    end

    def run_on(relation, params)
      relation.order("#{params[:field]} #{params[:order]}") if params[:field]
    end
  end
end