class Worker
  # Turn messages into command calls
  class MessageHandler
    alias Prefix = NamedTuple(string: String, allow_whitespace: Bool)

    DM_PREFIX             = {string: "", allow_whitespace: true}
    DOWNCASE_COMMAND_NAME = true
    COMMAND_NAME_REGEX    = /[a-zа-я]+/
    OPTION_PREFIX         = "--"
    OPTION_SEPARATOR      = "="

    Log = Worker::Log.for("message_handler")

    @default_prefix : String = Dusic.secrets["default_prefix"].as_s
    @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64

    def initialize(@worker : Worker)
    end

    def handle(text : String, server_id : UInt64, channel_id : UInt64) : Array(CommandCall)
      # NOTE: this method might return array of command calls in future. For instance:
      #   handle("!help\n!help") # => [CommandCall, CommandCall]
      Log.debug { "Handling text: #{text.inspect}" }

      text = text.strip
      prefix = find_prefix(text, server_id)
      return [] of CommandCall if prefix.nil?

      text = text.lchop(prefix[:string])
      old_length = text.size
      text = text.lstrip
      return [] of CommandCall if text.size != old_length && !prefix[:allow_whitespace]

      handle_command_text(text, server_id, channel_id)
    end

    private def handle_command_text(text : String, server_id : UInt64, channel_id : UInt64) : Array(CommandCall)
      words = text.split
      name = words.shift?
      return [] of CommandCall if name.nil?

      name = name.downcase if DOWNCASE_COMMAND_NAME
      return [] of CommandCall unless name.match(COMMAND_NAME_REGEX)

      options = {} of String => String?
      while word = words.shift?
        option_without_prefix = word.lchop?(OPTION_PREFIX)

        if option_without_prefix.nil? || option_without_prefix.empty?
          words.unshift(word)
          break
        end

        key, sep, val = option_without_prefix.partition(OPTION_SEPARATOR)

        options[key.downcase] = sep.empty? ? nil : val
      end

      [CommandCall.new(name, words, options, server_id, channel_id)]
    end

    private def find_prefix(text : String, server_id : UInt64) : Prefix?
      prefixes = prefixes(server_id)
      prefixes.find do |prefix|
        text.starts_with?(prefix[:string])
      end
    end

    private def prefixes(server_id : UInt64) : Array(Prefix)
      result : Array(Prefix) = [server_prefix(server_id)]
      result.concat(mention_prefixes)
      result << DM_PREFIX if server_id.zero?

      result
    end

    private def server_prefix(server_id : UInt64) : Prefix
      server_prefix : String? = begin
        @worker.api_client.server(server_id).setting.prefix
      rescue exception
        Log.error(exception: exception) { "failed to fetch prefix for server##{server_id}" }
        nil
      end

      {string: server_prefix || @default_prefix, allow_whitespace: false}
    end

    private def mention_prefixes : Array(Prefix)
      [
        {string: "<@#{@bot_id}>", allow_whitespace: true},
        {string: "<@!#{@bot_id}>", allow_whitespace: true},
      ]
    end
  end
end
