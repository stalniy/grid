module Grid
  class Api::Command::Filter < Api::Command
    def configure(relation, params)
      params.fetch(:filters, {}).inject({}) do |filters, pair|
        if pair.last.is_a?(Hash)
          filters[pair.first] = filter_based_on_hash(pair.last)
        else
          filters[pair.first] = pair.last
        end
        filters
      end
    end

    def run_on(relation, filters)
      conditions = build_conditions_for(relation, filters)
      relation = relation.where(conditions) unless conditions.blank?
      relation
    end

  private

    def build_conditions_for(relation, filters)
      conditions = filters.map do |name, filter|
        if filter.kind_of?(Array)
          relation.table[name].in(filter)
        elsif filter.kind_of?(Hash)
          expr = []
          expr << relation.table[name].gteq(filter[:from]) if filter.has_key?(:from)
          expr << relation.table[name].lteq(filter[:to])   if filter.has_key?(:to)
          expr.inject(:and)
        else
          relation.table[name].eq(filter)
        end
      end
      conditions.compact.inject(:and)
    end

    def filter_based_on_hash(value)
      # TODO: automatically detect if field is datetime and try to parse it with all known formats
      case value[:type].to_s
      when 'time'
        value[:from] = Time.at(value[:from].to_f) if value.has_key?(:from)
        value[:to]   = Time.at(value[:to].to_f)   if value.has_key?(:to)
      when 'date'
        value[:from] = Date.strptime(value[:from], Date::DATE_FORMATS[:date]) if value.has_key?(:from)
        value[:to]   = Date.strptime(value[:to],   Date::DATE_FORMATS[:date]) if value.has_key?(:to)
      end
      value
    end

  end
end
