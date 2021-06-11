require "./command_call_executor/*"

class Worker
  # Handle command calls
  class CommandCallExecutor
    enum AccessLevel
      Base
      ServerDj
      ServerAdministrator
      ServerOwner
      BotOwner
    end
    alias CommandData = NamedTuple(name: String, aliases: Array(String), allowed_in_dm: Bool, required_access_level: AccessLevel, callable: Command.class)

    Log = Worker::Log.for("command_call_executor")

    COMMANDS_LIST = [
      {
        name:                  "help",
        aliases:               ["help", "h"],
        allowed_in_dm:         true,
        required_access_level: AccessLevel::Base,
        callable:              HelpCommand,
      },
      {
        name:                  "settings",
        aliases:               ["settings", "options"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerAdministrator,
        callable:              SettingsCommand,
      },
      {
        name:                  "about",
        aliases:               ["about"],
        allowed_in_dm:         true,
        required_access_level: AccessLevel::Base,
        callable:              AboutCommand,
      },
      {
        name:                  "play",
        aliases:               ["play", "p", "resume"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              PlayCommand,
      },
      {
        name:                  "choose",
        aliases:               ["choose", "ch"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              ChooseCommand,
      },
      {
        name:                  "cancel",
        aliases:               ["cancel"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              CancelCommand,
      },
      {
        name:                  "skip",
        aliases:               ["skip", "s"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              SkipCommand,
      },
      {
        name:                  "remove",
        aliases:               ["remove"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              RemoveCommand,
      },
      {
        name:                  "stop",
        aliases:               ["stop"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              StopCommand,
      },
      {
        name:                  "leave",
        aliases:               ["leave", "pause"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              LeaveCommand,
      },
      {
        name:                  "shuffle",
        aliases:               ["shuffle"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              ShuffleCommand,
      },
      {
        name:                  "repeat",
        aliases:               ["repeat"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::ServerDj,
        callable:              RepeatCommand,
      },
      {
        name:                  "server",
        aliases:               ["server"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::Base,
        callable:              ServerCommand,
      },
      {
        name:                  "donate",
        aliases:               ["donate", "premium"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::Base,
        callable:              DonateCommand,
      },
      {
        name:                  "queue",
        aliases:               ["queue", "q"],
        allowed_in_dm:         false,
        required_access_level: AccessLevel::Base,
        callable:              QueueCommand,
      },
    ]

    def initialize(@worker : Worker)
    end

    def execute(command_call : CommandCall) : Nil
      begin
        COMMANDS_LIST.each do |data|
          if data[:aliases].includes?(command_call.name)
            Log.info { "Executing #{command_call}" }

            if command_call.server_id.zero? && !data[:allowed_in_dm]
              return UnavailableInDmCommand.new(@worker, command_call, data).execute
            end

            if author_access_level(command_call) < data[:required_access_level]
              return NotAuthorizedCommand.new(@worker, command_call, data).execute
            end

            return data[:callable].new(@worker, command_call, data).execute
          end
        end
      rescue exception
        Log.error(exception: exception) { "Unhandled exception during execution of #{command_call}" }

        return ErrorCommand.new(@worker, command_call).execute
      end

      UnknownCommand.new(@worker, command_call).execute
    end

    private def author_access_level(command_call) : AccessLevel
      bot_owner_id = Dusic.secrets["bot_owner_id"].as_s.to_u64
      return AccessLevel::BotOwner if command_call.author_id == bot_owner_id

      return AccessLevel::Base if command_call.server_id.zero?

      begin
        server_owner_id = @worker.discord_client.server_owner_id(command_call.server_id)
        return AccessLevel::ServerOwner if command_call.author_id == server_owner_id
      rescue exception : DiscordClient::NotFoundError
        Log.error(exception: exception) { "failed to fetch server owner id" }
      end

      author_roles = command_call.author_roles_ids

      begin
        admin_roles = @worker.discord_client.server_administrator_roles_ids(command_call.server_id)
        return AccessLevel::ServerAdministrator if (author_roles & admin_roles).any?
      rescue exception : DiscordClient::NotFoundError
        Log.error(exception: exception) { "failed to fetch server admin roles" }
      end

      dj_role = @worker.api_client.server(command_call.server_id).setting.dj_role
      return AccessLevel::ServerDj if dj_role.nil? || author_roles.includes?(dj_role)

      AccessLevel::Base
    rescue exception
      Log.error(exception: exception) { "failed to determine access level" }
      AccessLevel::ServerDj
    end
  end
end
