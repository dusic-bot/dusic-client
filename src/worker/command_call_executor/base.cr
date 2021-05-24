class Worker
  class CommandCallExecutor
    abstract class Base
      def initialize(@worker : Worker, @command_call : CommandCall)
      end

      abstract def execute

      private def reply(
        title : String,
        description : String,
        color_key : String? = nil,
        fields : Array(DiscordClient::EmbedFieldData) = Array(DiscordClient::EmbedFieldData).new
      ) : Nil
        color = color_key ? Dusic.color(color_key) : nil
        footer_text = "#{Dusic.ms_since(@command_call.call_time)}ms"
        @worker.discord_client.send_embed(@command_call.channel_id, title, description, footer_text, color, fields)
      end

      private def t(key : String, options : Hash | NamedTuple? = nil, force_locale = nil, count = nil, default = nil, iter = nil) : String
        locale = if force_locale
                   force_locale
                 elsif @command_call.server_id.zero?
                   I18n.default_locale
                 else
                   server.setting.language
                 end

        I18n.translate(key, options, locale, count, default, iter)
      end

      private def server : ApiClient::Mapping::Server
        @worker.api_client.server(@command_call.server_id)
      end

      private def prefix : String
        server.setting.prefix || Dusic.secrets["default_prefix"].as_s
      end

      private def premium? : Bool
        if donation = server.last_donation
          Time.utc <= donation.date + 31.day
        else
          false
        end
      end
    end
  end
end
