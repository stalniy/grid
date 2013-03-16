module Grid
  class Api
    attr_accessor :relation, :options

    def initialize(relation)
      @relation = relation
      @options = { :delegated_commands => {} }
    end

    def delegate(commands)
      options[:delegated_commands].merge! commands.stringify_keys
      self
    end

    def command_delegated?(cmd)
      options[:delegated_commands].has_key?(cmd)
    end

    def command(type)
      ::Grid::Api::Command.find(type)
    end

    def max_page(params = {})
      command(:paginate).calculate_max_page_for(relation, params)
    end

    def build_with!(params)
      params.fetch(:cmd).each do |cmd|
        run_command!(cmd, params) unless command(cmd).is_a?(::Grid::Api::Command::Batch)
      end
      self
    rescue ::Grid::Api::Command::UnknownCommandError, ::Grid::Api::Command::CommandWrongContext => e
      raise MessageError.new(e.message).tap{ |m| m.status(e.status) }
    end

    def run_command!(name, params)
      if command_delegated?(name)
        assoc_name = options[:delegated_commands][name]
        assoc = @relation.reflections[assoc_name].klass.scoped
        @relation = @relation.merge command(name).execute_on(assoc, params)
      else
        @relation = command(name).execute_on(@relation, params)
      end
    end

    class MessageError < StandardError
      attr_accessor :status
    end

  end
end