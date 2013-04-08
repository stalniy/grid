module Grid
  class Api::Command::Search < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:query] = params.fetch(:query, '').strip
        o[:searchable_columns] = params[:searchable_columns]
        o[:search_over] = params[:search_over]
        o[:search_over] = Hash[o[:search_over].zip] if o[:search_over].kind_of?(Array)
      end
    end

    def run_on(relation, params)
      if params[:query].blank?
        relation
      elsif params[:search_over].present?
        search_over(relation, params)
      else
        relation.where build_conditions_for(relation, params)
      end
    end

  private

    def searchable_columns_of(relation)
      relation.column_names.select do |column_name|
        relation.columns_hash[column_name].type == :string
      end
    end

    def build_conditions_for(relation, params)
      query = "%#{params[:query]}%"
      (params[:searchable_columns] || searchable_columns_of(relation)).map do |column|
        relation.table[column].matches(query)
      end.inject(:or)
    end

    def build_conditions_for_associations_of(relation, params)
      params[:search_over].each_with_object({}) do |options, conditions|
        assoc_name, assoc_fields = options
        assoc = relation.reflections[assoc_name.to_sym]
        assoc_condition = build_conditions_for(assoc.klass.scoped, params.merge(:searchable_columns => assoc_fields))
        conditions[assoc] = assoc_condition unless assoc_condition.blank?
      end
    end

    def search_over(relation, params)
      search_relation = relation.where(build_conditions_for(relation, params))
      assoc_conditions = build_conditions_for_associations_of(relation, params.except(:searchable_columns))
      matched_row_ids = row_ids_matched_for(search_relation, assoc_conditions)

      conditions = assoc_conditions.values
      conditions << relation.table.primary_key.in(matched_row_ids) unless matched_row_ids.blank?
      relation.where(conditions.inject(:or))
    end

    def row_ids_matched_for(relation, conditions)
      conditions.flat_map do |assoc, condition|
        query = join_relations_with(condition, relation, assoc).to_sql
        relation.connection.select_all(query).map(&:values)
      end.uniq
    end

    def join_relations_with(condition, relation, assoc)
      primary_key, foreign_key = relationship_between(relation, assoc)

      relation.select(relation.table.primary_key).
        where(assoc.klass.arel_table.primary_key.eq(nil)).
        joins("LEFT OUTER JOIN #{assoc.table_name} ON #{primary_key.eq(foreign_key).and(condition).to_sql}")
    end

    def relationship_between(relation, assoc)
      case assoc.macro
      when :belongs_to, :has_one
        primary_key = assoc.klass.arel_table.primary_key
        foreign_key = relation.table[assoc.foreign_key]
      when :has_many
        primary_key = relation.table.primary_key
        foreign_key = assoc.klass.arel_table[assoc.foreign_key]
      else
        raise ArgumentError, "Unable to search over #{assoc.macro}"
      end
      [ primary_key, foreign_key ]
    end

  end
end
