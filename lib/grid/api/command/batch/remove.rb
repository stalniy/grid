module Grid
  class Api::Command::Batch::Remove < Api::Command::Batch
    def configure(relation, params)
      super.tap do |params|
        raise BadContext, "There is nothing to remove" if params[:item_ids].blank?
      end
    end

    def run_on(relation, params)
      relation.where(relation.scoped.table.primary_key.in(params[:item_ids])).destroy_all
    end
  end
end