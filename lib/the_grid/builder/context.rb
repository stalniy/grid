module TheGrid
  class Builder::Context
    attr_reader :columns, :scope

    def initialize(options = {}, &dsl)
      @scope    = options.delete(:scope)
      @columns  = build_columns_with(options.delete(:id))
      @options  = options.merge(:features => [])

      self.instance_eval(&dsl)
    end

    def column(name, attributes = {}, &block)
      find_or_build_column(name).tap do |column|
        column.merge! attributes
        column[:as] = block if block_given?
      end
    end

    def method_missing(method_name, *args, &block)
      if @scope.respond_to?(method_name)
        @scope.send(method_name, *args, &block)
      elsif method_name.to_s.ends_with?("ble_columns")
        @options[:features] << method_name.to_s.chomp("_columns").to_sym
        mark_columns_with(@options[:features].last, args)
      else
        @options[method_name] = args.size == 1 ? args.first : args
      end
    end

    def scope_for(scope_name, attributes = {}, &block)
      name = attributes.delete(:as) || scope_name
      column name, attributes.merge(:as => Builder::Context.new(:scope => scope, &block), :scope_name => scope_name)
    end

    def options
      @options.except(:features)
    end

    def params
      self.options.merge self.featured_columns
    end

    def visible_columns
      columns.each_with_object({}) do |(name,options), vc|
        vc[name] = options.except(:as, :if, :unless) unless options[:hidden]
        vc[name] = {:columns => options[:as].visible_columns} if options[:as].respond_to?(:visible_columns)
      end
    end

    def assemble(records)
      records.map{ |record| assemble_row_for(record) }
    end

  protected

    def build_columns_with(id_field)
      columns = {}
      columns[id_field || :id] = {:hidden => true} unless id_field === false
      columns
    end

    def find_or_build_column(name)
      @columns[name.to_sym] ||= {}
    end

    def mark_columns_with(feature, column_names)
      column_names.each do |name|
        find_or_build_column(name).store(feature, true)
      end
    end

    def featured_columns
      @options[:features].each_with_object({}) do |feature, types|
        types[:"#{feature}_columns"] = columns.select{ |name, attrs| attrs[feature] }.keys
      end
    end

    def assemble_row_for(record)
      columns.each_with_object({}) do |column, row|
        name, options = column
        row[name] = assemble_column_for(record, name, options)
      end
    end

    def assemble_column_for(record, name, options)
      formatter = options[:as]

      if formatter.respond_to?(:call)
        formatter.call(record)
      elsif formatter.is_a? Symbol
        record.send(formatter)
      elsif formatter.respond_to?(:assemble)
        formatter.assemble(record.send(options[:scope_name])) if may_assemble?(record, options)
      else
        record.send(name)
      end
    end

    def may_assemble?(record, options)
      condition = options[:if] || options[:unless]

      if condition.is_a? Symbol
        result = assemble_column_for(record, condition, columns[condition])
      elsif condition.respond_to?(:call)
        result = condition.call(record)
      else
        result = true
      end
      options[:unless].present? ? !result : result
    end

  end
end
