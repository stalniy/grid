module Grid
  class Api::Command

    def self.find(cmd)
      @@commands ||= {}
      @@commands[cmd] ||= build!(cmd)
    end

    def self.register_lookup_scope(scope)
      scopes.unshift(scope)
    end

    def self.scopes
      @@scopes ||= ["grid/api/command"]
    end

    def self.build!(cmd)
      scope = scopes.detect do |scope|
        classify!("#{scope}/#{cmd}") rescue nil
      end
      raise UnknownCommandError, %{ Command "#{cmd}" is unknown" } if scope.nil?
      classify!("#{scope}/#{cmd}").new
    end

    def execute_on(relation, params)
      run_on(relation, configure(relation, params))
    end

  private

    def run_on(relation, params)
      raise "Method \"#{inspect}::run_on\" should be implemented by child class"
    end

    def configure(relation, params)
      params
    end

    def self.classify!(path)
      constant = Object
      path.split('/').each do |name|
        name = name.capitalize.gsub(/_([a-z])/){ $1.capitalize }
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

    class UnknownCommandError < StandardError
      def status
        'error'
      end
    end

    class BadContext < StandardError
      def status
        'error'
      end
    end

  end
end