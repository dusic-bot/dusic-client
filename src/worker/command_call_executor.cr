require "./command_call_executor/*"

class Worker
  # Handle command calls
  class CommandCallExecutor
    Log = Worker::Log.for("command_call_executor")

    COMMANDS_LIST = {
      help:     ["help", "h"],
      settings: ["settings", "options"],
      about:    ["about"],
      play:     ["play", "p", "resume"],
      choose:   ["choose", "ch"],
      cancel:   ["cancel"],
      skip:     ["skip", "s"],
      remove:   ["remove"],
      stop:     ["stop"],
      leave:    ["leave", "pause"],
      shuffle:  ["shuffle"],
      repeat:   ["repeat"],
      server:   ["server"],
      donate:   ["donate", "premium"],
      queue:    ["queue", "q"],
    }

    def initialize(@worker : Worker)
    end

    def execute(command_call : CommandCall) : Nil
      begin
        {% for command, aliases in COMMANDS_LIST %}
          if {{ aliases }}.includes?(command_call.name)
            Log.info { "Executing #{command_call}" }
            return {{ command.capitalize }}Command.new(@worker, command_call).execute
          end
        {% end %}
      rescue exception
        Log.error(exception: exception) { "Unhandled exception during execution of #{command_call}" }

        return ErrorCommand.new(@worker, command_call).execute
      end

      UnknownCommand.new(@worker, command_call).execute
    end
  end
end
