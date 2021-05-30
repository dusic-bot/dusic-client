require "./base"

class Worker
  class CommandCallExecutor
    class SettingsCommand < Base
      ROLE_ID_OR_MENTION_REGEX = /^(?:(\d+)|<@&(\d+)>)$/

      def execute
        if @command_call.server_id.zero?
          reply(
            t("commands.settings.title"),
            t("commands.settings.errors.only_available_in_guild_channels"),
            "danger"
          )
          return
        end

        if author_access_level < AccessLevel::ServerAdministrator
          reply(
            t("commands.settings.title"),
            t("commands.settings.errors.only_available_for_administrators"),
            "danger"
          )
          return
        end

        if @command_call.arguments.empty?
          reply_with_current_settings
          return
        end

        setting = @command_call.arguments[0]
        value = @command_call.arguments[1..].join(" ")

        case setting
        when "dj_role"   then update_dj_role_setting(value)
        when "language"  then update_language_setting(value)
        when "autopause" then update_autopause_setting(value)
        when "prefix"    then update_prefix_setting(value)
        else
          reply(
            t("commands.settings.title"),
            t("commands.settings.errors.unknown_setting", {setting: setting}),
            "danger"
          )
        end
      end

      private def reply_with_current_settings : Nil
        dj_role_text : String = if dj_role_id = server.setting.dj_role
          begin
            @worker.discord_client.role_name(dj_role_id)
          rescue exception : DiscordClient::NotFoundError
            Log.error(exception: exception) { "failed to fetch role name for #{dj_role_id} at #{@command_call.server_id}" }
            dj_role_id.to_s
          end
        else
          t("commands.settings.text.not_defined")
        end
        language_name = server.setting.language.upcase
        autopause_status = server.setting.autopause ? "ON" : "OFF"

        reply(
          t("commands.settings.title"),
          t("commands.settings.text.all_settings", {
            dj_role:   dj_role_text,
            language:  language_name,
            autopause: autopause_status,
            prefix:    prefix,
          }),
          "success"
        )
      end

      private def update_dj_role_setting(value : String) : Nil
        if value.empty? || value == "@everyone"
          server.setting.dj_role = nil
          @worker.api_client.server_save(server)
          reply(
            t("commands.settings.title"),
            t("commands.settings.text.dj_role_reset"),
            "success"
          )
          return
        end

        if new_role_data = role_by_mention(value)
          server.setting.dj_role = new_role_data[:id]
          @worker.api_client.server_save(server)
          content = if new_role_data[:name]
                      t("commands.settings.text.new_dj_role", {dj_role: new_role_data[:name]})
                    else
                      t("commands.settings.text.new_dj_role_id", {dj_role_id: new_role_data[:id]})
                    end
          reply(t("commands.settings.title"), content, "success")
        else
          reply(
            t("commands.settings.title"),
            t("commands.settings.errors.failed_to_find_role"),
            "danger"
          )
        end
      end

      private def update_language_setting(value : String) : Nil
        new_language = case value
                       when "русский", "ру", "ru", "russian"             then "ru"
                       when "английский", "англ", "en", "eng", "english" then "en"
                       else
                         "ru"
                       end

        server.setting.language = new_language
        @worker.api_client.server_save(server)
        reply(
          t("commands.settings.title"),
          t("commands.settings.text.new_language", {language: new_language}),
          "success"
        )
      end

      private def update_autopause_setting(value : String) : Nil
        # TODO
      end

      private def update_prefix_setting(value : String) : Nil
        # TODO
      end

      private def role_by_mention(value : String) : NamedTuple(name: String?, id: UInt64)?
        new_role_id = if new_role_id_match = value.match(ROLE_ID_OR_MENTION_REGEX)
                        (new_role_id_match[1]? || new_role_id_match[2]?).try &.to_u64?
                      else
                        nil
                      end

        if new_role_id && valid_role_id?(new_role_id)
          begin
            {name: @worker.discord_client.role_name(new_role_id), id: new_role_id}
          rescue DiscordClient::NotFoundError
            {name: nil, id: new_role_id}
          end
        else
          begin
            {name: value, id: @worker.discord_client.role_id_by_name(value)}
          rescue DiscordClient::NotFoundError
            nil
          end
        end
      end

      private def valid_role_id?(id : UInt64) : Bool
        (id >> 22) > 0
      end
    end
  end
end
