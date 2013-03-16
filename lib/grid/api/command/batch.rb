module Grid
  class Api::Command::Batch < Api::Command
    def configure(relation, params)
      {}.tap do |o|
        o[:item_ids] = params.fetch(:item_ids, []).reject{ |id| id.to_i.zero? }
        o[:items] = params.fetch(:items, {}).reject{ |k, item| item['id'].to_i.zero? }
      end
    end
  end
end