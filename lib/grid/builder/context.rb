module Grid
  class Builder::Context
    attr_accessor :columns, :options, :scope, :name

    def initialize(options = {})
      @name  = options.delete(:name)
      @scope = options.delete(:scope)
      @options = options
      @columns = create_columns
    end

    def column(name, options = {}, &block)
      find_or_build_column(name).merge! create_column(options, &block)
    end

    def visible_columns
      columns.inject({}) do |visible_columns, col|
        visible_columns[col.first] = col.last.except(:as, :if, :unless) unless col.last[:hidden]
        visible_columns
      end
    end

    def column_names_marked_as(feature)
      columns.map{ |name, column| name if column[feature].present? }.compact
    end

    def method_missing(method_name, *args, &block)
      if @scope.respond_to?(method_name)
        @scope.send(method_name, *args, &block)
      elsif method_name.to_s.ends_with?("ble_columns")
        feature = method_name.to_s.tap{ |m| m.slice!("_columns") }
        mark_columns_with(feature.to_sym, args)
      else
        @options[method_name] = args.size == 1 && args.first.is_a?(Hash) ? args.first : args
      end
    end

    def scope_for(name, options = {}, &block)
      column_name = options.delete(:as) || name
      nested_context = Builder::Context.new(:scope => scope, :name => name).tap{ |ctx| block.bind(ctx).call }
      column column_name, options.merge(:as => nested_context)
    end

    def convert(records)
      records.map{ |record| build_row_for(record) }
    end

  protected

    def create_columns
      { :id => {:hidden => true} }
    end

    def create_column(options, &block)
      options.tap do |o|
        o[:as] = block if block_given?
      end
    end

    def find_or_build_column(name)
      @columns ||= {}
      @columns[name.to_sym] ||= {}
    end

    def mark_columns_with(feature, column_names)
      column_names.each do |name|
        find_or_build_column(name).store(feature, true)
      end
    end

    def build_row_for(record)
      columns.inject({}) do |row, column|
        row[column.first] = build_column_for(record, column.first, column.last)
        row
      end
    end

    def build_column_for(record, name, options)
      formatter = options[:as]

      if formatter.respond_to?(:call)
        formatter.call(record)
      elsif formatter.is_a? Symbol
        record.send(formatter)
      elsif formatter.is_a? Builder::Context
        formatter.convert(record.send(formatter.name)) if can_convert?(record, options)
      else
        record.send(name)
      end
    end

    def can_convert?(record, options)
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