require "./command"

class Worker
  class CommandCallExecutor
    class ChooseCommand < Command
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

        apply_option_aliases!

        space_left = audio_player.queue.limit - audio_player.queue.size
        if audios.size > space_left
          audios = audios.first(space_left)
          reply(t("commands.choose.title"), t("audio_player.text.queue_limit_hit"), "warning")
        end

        audios.shuffle! if @command_call.options.has_key?("shuffle")

        if @command_call.options.has_key?("skip")
          audio_player.skip
        end

        if @command_call.options.has_key?("first")
          audio_player.queue.unshift(audios)
        else
          audio_player.queue.push(audios)
        end

        reply_to_added_audios(audios)

        audio_player.play
      end

      private def apply_option_aliases! : Nil
        options = @command_call.options
        if options.has_key?("now")
          options["first"] = options["skip"] = options["instant"] = nil
        end
      end

      private def reply_to_added_audios(audios : AudioPlayer::AudioArray, title : String? = nil) : Nil
        if audios.empty?
          reply(t("commands.play.title"), t("commands.play.text.nothing_found"), "warning")
        elsif audios.size == 1
          reply(
            t("audio_player.title"),
            t("audio_player.text.audio_added", {
              artist:   audios.first.artist,
              title:    audios.first.title,
              duration: Dusic.format_seconds(audios.first.duration),
            }),
            "success"
          )
        elsif title
          reply(
            t("audio_player.title"),
            t("audio_player.text.audio_list_added", {title: title}, count: audios.size),
            "success"
          )
        else
          reply(t("audio_player.title"), t("audio_player.text.audios_added", count: audios.size), "success")
        end
      end
    end
  end
end
