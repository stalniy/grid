module Grid
  class Api::Command::BatchRemove < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:item_ids] = params.fetch(:item_ids, []).reject{ |id| id.to_i <= 0 }
        raise ArgumentError, "There is nothing to remove" if o[:item_ids].blank?
      end
    end

    def run_on(relation, params)
      relation.where(relation.scoped.table.primary_key.in(params[:item_ids])).destroy_all
    end
  end
end
