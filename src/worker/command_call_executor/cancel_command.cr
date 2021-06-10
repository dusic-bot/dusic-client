require "./command"

class Worker
  class CommandCallExecutor
    class CancelCommand < Command
      def execute : Nil
        selection = @worker.audio_selections_storage[@command_call.server_id, @command_call.author_id]?
        if selection.nil?
          reply(t("commands.cancel.title"), t("commands.cancel.errors.call_play_first"), "danger")
          return
        end

        @worker.audio_selections_storage.delete(@command_call.server_id, @command_call.author_id)

        if message_id = selection.message_id
          @worker.discord_client.delete_message(selection.channel_id, message_id)
        end

        reply(t("commands.cancel.title"), t("commands.cancel.text.selection_canceled"), "success")
      end
    end
  end
end
