require "./command/*"

class Worker
  class CommandCallExecutor
    abstract class Command
      def initialize(@worker : Worker, @command_call : CommandCall, @command_data : CommandData? = nil)
      end

      abstract def execute

      private def reply(
        title : String,
        description : String,
        color_key : String? = nil,
        fields : Array(DiscordClient::EmbedFieldData) = Array(DiscordClient::EmbedFieldData).new
      ) : UInt64?
        color = color_key ? Dusic.color(color_key) : nil
        footer_text = "#{Dusic.ms_since(@command_call.call_time)}ms"
        @worker.discord_client.send_embed(@command_call.channel_id, title, description, footer_text, color, fields)
      end

      private def t(*args, **opts) : String
        Dusic.t(*args, **opts) do
          if @command_call.server_id.zero?
            I18n.default_locale
          else
            server.setting.language
          end
        end
      end

      private def server : ApiClient::Mapping::Server
        @worker.api_client.server(@command_call.server_id)
      end

      private def audio_player : AudioPlayer
        @worker.audio_players_storage.audio_player(@command_call.server_id)
      end

      private def prefix : String
        server.setting.prefix || Dusic.secrets["default_prefix"].as_s
      end

      private def premium? : Bool
        server.premium?
      end
    end
  end
end
