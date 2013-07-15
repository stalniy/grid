module TheGrid
  class Builder
    private_class_method :new

    autoload :Context, 'the_grid/builder/context'
    autoload :Csv,     'the_grid/builder/csv'
    autoload :Json,    'the_grid/builder/json'

    def self.call(template)
      source = if template.source.empty?
        File.read(template.identifier)
      else
        template.source
      end

      %{
        ::TheGrid::Builder.assemble(:format => #{template.formats.first.inspect}, :scope => self) {
          #{source}
        }
      }
    end

    def self.detect_view(format)
      @@view_types ||= {}
      @@view_types[format] ||= "the_grid/builder/#{format}".camelize.constantize
    end

    def self.assemble(options, &block)
      new(options, &block).instance_eval(&block)
    end

    def initialize(options, &block)
      options.assert_valid_keys(:scope, :format)

      @_scope = options.delete(:scope)
      @_view_type = self.class.detect_view(options.delete(:format))

      copy_instance_variables_from(@_scope) if @_scope
      self.instance_eval(&block)
    end

    def grid_for(relation, options = {}, &block)
      context = Context.new(options.merge(:scope => @_scope), &block)
      @_view_type.assemble(context, :on => relation, :with => @_scope.params.merge(context.params))
    end

    def method_missing(name, *args, &block)
      if @_scope.respond_to?(name)
        @_scope.send(name, *args, &block)
      else
        super
      end
    end

  private

    def copy_instance_variables_from(object)
      vars = object.instance_variables.map(&:to_s)
      vars.each{ |name| instance_variable_set(name.to_sym, object.instance_variable_get(name)) }
    end


    module Base

      def compose(records, params)
        api = ::TheGrid::Api.new(records)
        api.compose!(params)
        api
      end

      def assemble(context, options)
        options.assert_valid_keys(:on, :with)
        params = options[:with].merge context.params
        build(context, :for => options[:on], :with => params)
      rescue ArgumentError => error
        stringify :status => 'error', :message => error.message
      end

      def stringify(data)
        data.inspect
      end

      def build
        raise NotImplementedError
      end

    end

  end
end
