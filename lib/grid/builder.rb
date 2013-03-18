module Grid
  class Builder
    private_class_method :new

    def self.call(template)
      source = if template.source.empty?
        File.read(template.identifier)
      else
        template.source
      end

      %{
        ::Grid::Builder.assemble(:view_type => ::Grid::Builder::Json, :scope => self){
          #{source}
        }
      }
    end

    def self.assemble(options, &block)
      builder = new(options)
      block.bind(builder).call if block_given?
      builder
    end

    def initialize(options)
      options.assert_valid_keys(:scope, :view_type)

      @_scope = options.delete(:scope)
      @_view_type = options.delete(:view_type)
      copy_instance_variables_from(@_scope) if @_scope
    end

    def grid_for(relation, options = {}, &block)
      context = Context.new(options.merge(:scope => @_scope))
      block.bind(context).call
      @_view_handler = @_view_type.new(relation, context)
    end

    def to_str
      @_view_handler.assemble_with(@_scope.params)
    end
    
    def to_s
      self.to_str
    end
    
    def handler
      @_view_handler
    end

    def method_missing(name, *args, &block)
      if @_scope.respond_to?(name)
        @_scope.send(name, *args, &block)
      else
        super
      end
    end

  private

    def copy_instance_variables_from(object, exclude = [])
      vars = object.instance_variables.map(&:to_s) - exclude.map(&:to_s)
      vars.each { |name| instance_variable_set(name.to_sym, object.instance_variable_get(name)) }
    end

  end
end
