module TheGrid
  class Api
    attr_reader :relation, :options

    def initialize(relation)
      @relation = relation
      @options = { :delegated_commands => {} }
    end

    def delegate(commands)
      options[:delegated_commands].merge! commands.stringify_keys
    end

    def compose!(params)
      configure(params).fetch(:cmd).each do |cmd|
        @relation = run_command!(cmd, params) unless command(cmd).batch?
      end
    end

    def run_command!(name, params)
      @options.merge! command(name).contextualize(@relation, params)

      if command_delegated?(name)
        assoc_name = options[:delegated_commands][name.to_s]
        assoc = @relation.reflections[assoc_name].klass.scoped
        @relation.merge command(name).execute_on(assoc, params)
      else
        command(name).execute_on(@relation, params)
      end
    end

  protected

    def command(type)
      ::TheGrid::Api::Command.find(type)
    end

    def command_delegated?(cmd)
      options[:delegated_commands] && options[:delegated_commands].has_key?(cmd.to_s)
    end

    def configure(params)
      self.delegate(params[:delegate]) if params[:delegate]
      params.tap do |o|
        o[:cmd] = Array.wrap(o[:cmd])
        o[:cmd].unshift(:paginate) unless params[:per_page] === false
        o[:cmd].uniq!
      end
    end

  end
end
