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
        ::Grid::Builder.assemble(:view_type => ::Grid::Builder::Json, :scope => self) {
          #{source}
        }
      }
    end

    def self.assemble(options, &block)
      new(options, &block)
    end

    def initialize(options, &block)
      options.assert_valid_keys(:scope, :view_type)

      @_scope = options.delete(:scope)
      @_view_type = options.delete(:view_type)
      
      copy_instance_variables_from(@_scope) if @_scope
      self.instance_eval(&block)
    end

    def grid_for(relation, options = {}, &block)
      context = Context.new(options.merge(:scope => @_scope), &block)
      @_view_handler = @_view_type.new(relation, context)
    end
    
    def assemble(&block)
      @_view_handler.assemble_with(@_scope.params, &block)
    end

    def method_missing(name, *args, &block)
      if @_scope.respond_to?(name)
        @_scope.send(name, *args, &block)
      else
        super
      end
    end
    
    def to_s; assemble;end
    def to_str; assemble;end

  private

    def copy_instance_variables_from(object)
      vars = object.instance_variables.map(&:to_s)
      vars.each { |name| instance_variable_set(name.to_sym, object.instance_variable_get(name)) }
    end

  end
end
