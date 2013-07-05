module TheGrid
  module Builder::Json
    extend self, Builder::Base
    mattr_accessor :prettify_json

    def build(context, params)
      api, options = compose(params[:for], params[:with]), params[:with]
      json = {:max_page => api.options[:max_page], :items => context.assemble(api.relation)}
      if options[:with_meta]
        json[:meta] = context.options.except(:delegate, :search_over)
        json[:columns] = columns_as_array(context.visible_columns)
      end
      stringify json
    end

  private

    def stringify(json_hash)
      self.prettify_json ? JSON.pretty_generate(json_hash) : json_hash.to_json
    end

    def columns_as_array(columns)
      columns.map do |name, options|
        options[:columns] = columns_as_array(options[:columns]) if options[:columns].is_a? Hash
        options.merge :name => name
      end
    end

  end
end
