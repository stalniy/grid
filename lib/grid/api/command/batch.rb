module Grid
  class Api::Command::Batch < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:item_ids] = params.fetch(:item_ids, []).reject{ |id| id.to_i <= 0 }
        o[:items] = params.fetch(:items, []).reject{ |item| item['id'].to_i <= 0 }
      end
    end
  end
end