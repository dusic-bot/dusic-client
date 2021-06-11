require "./command"

class Worker
  class CommandCallExecutor
    class ChooseCommand < Command
      include Command::WithAudiosAddition

      SPLITTER_REGEX = /(?:\s*,\s*|,?\s+)/

      def execute : Nil
        selection = @worker.audio_selections_storage[@command_call.server_id, @command_call.author_id]?

        if selection.nil?
          reply(t("commands.choose.title"), t("commands.choose.errors.call_play_first"), "danger")
          return
        end

        if audio_player.queue.full?
          reply(t("commands.choose.title"), t("audio_player.text.audio_queue_full"), "danger")
          return
        end

        argument = @command_call.arguments.join(" ")
        if argument.empty?
          reply(t("commands.choose.title"), t("commands.choose.errors.nothing_select"), "danger")
          return
        end

        indexes = [] of Int32
        subs = argument.split(SPLITTER_REGEX, remove_empty: true)
        subs.each do |s|
          i = s.to_i32?
          indexes.push(i - 1) if i && i > 0
        end

        audios = selection.fetch(indexes)
        if audios.empty?
          reply(t("commands.choose.title"), t("commands.choose.errors.nothing_selected"), "danger")
          return
        end

        @worker.audio_selections_storage.delete(selection)

        apply_audios_addition_option_aliases!

        space_left = audio_player.queue.limit - audio_player.queue.size
        if audios.size > space_left
          audios = audios.first(space_left)
          reply(t("commands.choose.title"), t("audio_player.text.queue_limit_hit"), "warning")
        end

        add_and_play(audios)
      end
    end
  end
end
