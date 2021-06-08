require "./command"

class Worker
  class CommandCallExecutor
    class HelpCommand < Command
      HELP_SECTIONS = [
        {name: "_question_mark", inline: false},
        {name: "help", inline: false},
        {name: "about", inline: true},
        {name: "donate", inline: true},
        {name: "_musical_sign", inline: false},
        {name: "play", inline: false},
        {name: "_musical_line_sign", inline: false},
        # {name: "cancel", inline: true},
        # {name: "choose", inline: true},
        {name: "queue", inline: false},
        {name: "leave", inline: true},
        {name: "stop", inline: true},
        {name: "skip", inline: true},
        {name: "remove", inline: true},
        {name: "repeat", inline: true},
        {name: "shuffle", inline: true},
        {name: "_gear", inline: false},
        {name: "server", inline: false},
        {name: "settings", inline: false},
      ]

      def execute : Nil
        argument = @command_call.arguments.first? || ""
        argument = argument.strip.downcase
        if name = find_main_command_name(argument)
          reply(t("commands.help.title"), t("commands.help.text.detailed.#{name}"), "success")
          return
        end

        reply_with_full_message
      end

      private def find_main_command_name(name : String) : String?
        COMMANDS_LIST.each do |data|
          return data[:name] if data[:aliases].includes?(name)
        end

        nil
      end

      private def reply_with_full_message
        reply(
          t("commands.help.title"),
          "",
          "success",
          HELP_SECTIONS.map do |section|
            {
              title:       t("commands.help.section_title.#{section[:name]}"),
              inline:      section[:inline],
              description: t("commands.help.text.section.#{section[:name]}"),
            }
          end
        )
      end
    end
  end
end
