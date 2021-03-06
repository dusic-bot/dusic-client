class Worker
  class CommandCallExecutor
    abstract class Command
      module WithAudiosAddition
        private def apply_audios_addition_option_aliases! : Nil
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

        private def play_or_reply_with_error : Nil
          if audio_player.queue.empty?
            reply(t("audio_player.title"), t("audio_player.text.queue_is_empty"), "warning")
            return
          end

          if voice_channel_id = @command_call.voice_channel_id
            audio_player.play(voice_channel_id)
          else
            reply(t("audio_player.title"), t("audio_player.errors.you_are_not_in_vc"), "warning")
          end
        end

        private def add_and_play(audios : AudioPlayer::AudioArray, title : String? = nil) : Nil
          audios.shuffle! if @command_call.options.has_key?("shuffle")

          if @command_call.options.has_key?("skip")
            audio_player.skip
          end

          if @command_call.options.has_key?("first")
            audio_player.queue.unshift(audios)
          else
            audio_player.queue.push(audios)
          end

          reply_to_added_audios(audios, title)

          play_or_reply_with_error
        end
      end
    end
  end
end
