module Grid
  class Builder::Context
    attr_reader :columns, :options, :scope, :name

    def initialize(options = {}, &block)
      @name    = options.delete(:name)
      @scope   = options.delete(:scope)
      @options = options
      @columns = { :id => {:hidden => true} }
      
      self.instance_eval(&block)
    end

    def column(name, attributes = {}, &block)
      find_or_build_column(name).tap do |column|
        column.merge! attributes
        column[:as] = block if block_given?
      end
    end

    def visible_columns
      columns.inject({}) do |vc, column|
        name, options = column
        vc[name] = options.except(:as, :if, :unless) unless options[:hidden]
        vc[name] = options[:as].visible_columns if options[:as].respond_to?(:visible_columns)
        vc
      end
    end

    def method_missing(method_name, *args, &block)
      if @scope.respond_to?(method_name)
        @scope.send(method_name, *args, &block)
      elsif method_name.to_s.ends_with?("ble_columns")
        feature = method_name.to_s.tap{ |m| m.slice!("_columns") }
        mark_columns_with(feature.to_sym, args)
        @options[method_name.to_sym] = args
      else
        @options[method_name] = args.size == 1 && args.first.is_a?(Hash) ? args.first : args
      end
    end

    def scope_for(name, attributes = {}, &block)
      column_name = attributes.delete(:as) || name
      column column_name, attributes.merge(:as => Builder::Context.new(:scope => scope, :name => name, &block))
    end

    def assemble(records)
      records.map{ |record| build_row_for(record) }
    end

  protected

    def find_or_build_column(name)
      @columns[name.to_sym] ||= {}
    end

    def mark_columns_with(feature, column_names)
      column_names.each do |name|
        find_or_build_column(name).store(feature, true)
      end
    end

    def build_row_for(record)
      columns.inject({}) do |row, column|
        name, options = column
        row.merge name => build_column_for(record, name, options)
      end
    end

    def build_column_for(record, name, options)
      formatter = options[:as]

      if formatter.respond_to?(:call)
        formatter.call(record)
      elsif formatter.is_a? Symbol
        record.send(formatter)
      elsif formatter.respond_to?(:assemble)
        formatter.assemble(record.send(formatter.name)) if may_assemble?(record, options)
      else
        record.send(name)
      end
    end

    def may_assemble?(record, options)
      condition = options[:if] || options[:unless]

      if condition.is_a? Symbol
        result = build_column_for(record, condition, columns[condition])
      elsif condition.respond_to?(:call)
        result = condition.call(record)
      else
        result = true
      end
      options[:unless].present? ? !result : result
    end

  end
end
