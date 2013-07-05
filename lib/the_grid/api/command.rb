module TheGrid
  class Api::Command

    autoload :BatchRemove, 'the_grid/api/command/batch_remove'
    autoload :BatchUpdate, 'the_grid/api/command/batch_update'
    autoload :Filter,      'the_grid/api/command/filter'
    autoload :Paginate,    'the_grid/api/command/paginate'
    autoload :Search,      'the_grid/api/command/search'
    autoload :Sort,        'the_grid/api/command/sort'


    def self.find(cmd)
      @@commands ||= {}
      @@commands[cmd] ||= build(cmd)
    end

    def self.register_lookup_scope(scope)
      scopes.unshift(scope).uniq!
    end

    def self.scopes
      @@scopes ||= ["the_grid/api/command"]
    end

    def self.build(cmd)
      scope = scopes.detect do |scope|
        "#{scope}/#{cmd}".camelize.constantize rescue nil
      end
      raise ArgumentError, %{ Command "#{cmd}" is unknown } if scope.nil?
      "#{scope}/#{cmd}".camelize.constantize.new
    end

    def execute_on(relation, params)
      run_on(relation, configure(relation, params))
    end

    def batch?
      @is_batch ||= self.class.name.demodulize.starts_with?('Batch')
    end

    def contextualize(relation, params)
      {}
    end

  protected

    def run_on(relation, params)
      raise "Method \"#{inspect}::run_on\" should be implemented by child class"
    end

    def configure(relation, params)
      params
    end

  end
end
