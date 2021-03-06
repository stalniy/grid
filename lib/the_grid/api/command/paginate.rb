module TheGrid
  class Api::Command::Paginate < Api::Command
    cattr_accessor(:default_per_page){ 10 }

    def configure(relation, params)
      {}.tap do |o|
        o[:page] = params[:page].to_i
        o[:page] = 1 if o[:page] <= 0
        o[:size] = params[:size]

        o[:per_page] = params[:per_page].to_i
        o[:per_page] = self.class.default_per_page if o[:per_page] <= 0
      end
    end

    def run_on(relation, params)
      relation.offset((params[:page] - 1) * params[:per_page]).limit(params[:per_page])
    end

    def calculate_max_page_for(relation, params)
      params = configure(relation, params)
      total_count = params[:size].present? ? params[:size] : relation.except(:limit, :offset, :includes).count
      (total_count / params[:per_page].to_f).ceil
    end

    def contextualize(relation, params)
      {:max_page => calculate_max_page_for(relation, params)}
    end

  end
end
