module Grid
  class Api
    attr_reader :relation, :options

    def initialize(relation)
      @relation = relation
      @options = { :delegated_commands => {} }
    end

    def delegate(commands)
      options[:delegated_commands].merge! commands.stringify_keys
    end

    def build_with!(params)
      params.fetch(:cmd).each do |cmd|
        @relation = run_command!(cmd, params) unless command(cmd).batch?
      end
    end

    def run_command!(name, params)
      command(name).prepare_context(self, params)

      if command_delegated?(name)
        assoc_name = options[:delegated_commands][name]
        assoc = @relation.reflections[assoc_name].klass.scoped
        @relation.merge command(name).execute_on(assoc, params)
      else
        command(name).execute_on(@relation, params)
      end
    end

  protected

    def command(type)
      ::Grid::Api::Command.find(type)
    end

    def command_delegated?(cmd)
      options[:delegated_commands].has_key?(cmd)
    end

  end
end
