module TheGrid
  class Api::Command::Filter < Api::Command
    def configure(relation, params)
      params.fetch(:filters, {}).dup
    end

    def run_on(relation, filters)
      conditions = build_conditions_for(relation, filters)
      relation = relation.where(conditions) unless conditions.blank?
      relation
    end

  private

    def build_conditions_for(relation, filters)
      conditions = filters.map do |name, filter|
        column = column_for(relation, name)

        if filter.kind_of?(Array)
          column.in(filter)
        elsif filter.kind_of?(Hash)
          expr = []
          expr << column.gteq(prepare_value filter, :from) if filter.has_key?(:from)
          expr << column.lteq(prepare_value filter, :to)   if filter.has_key?(:to)
          expr.inject(:and)
        else
          column.eq(filter)
        end
      end
      conditions.compact.inject(:and)
    end

    def prepare_value(filter, name)
      case filter[:type].to_s
      when 'time'
        Time.at(Float filter[name])
      when 'date'
        filter[name].to_time
      else
        filter[name]
      end
    end

  end
end
