require "./command"

class Worker
  class CommandCallExecutor
    class RepeatCommand < Command
      def execute : Nil
        space_left = audio_player.queue.limit - audio_player.queue.size
        if space_left <= 0
          reply(t("audio_player.title"), t("audio_player.text.audio_queue_full"), "danger")
          return
        end

        count : Int32 = @command_call.arguments.first?.try &.to_i32? || 1
        count = 1 if count <= 0
        count = space_left if count > space_left

        current_audio = audio_player.current_audio
        if current_audio.nil?
          reply(t("commands.repeat.title"), t("commands.repeat.errors.nothing_is_playing"), "danger")
          return
        end

        audios = Array.new(count, current_audio)
        audio_player.queue.unshift(audios)

        reply(t("commands.repeat.title"), t("commands.repeat.text.audios_added", count: count), "success")
      end
    end
  end
end
