require "./command"

class Worker
  class CommandCallExecutor
    class ServerCommand < Command
      def execute : Nil
        reply(
          t("commands.server.title"),
          t("commands.server.text.statistic", {
            server_id:           @command_call.server_id,
            total_tracks_length: Dusic.format_seconds(server.statistic.tracks_length),
            total_tracks_amount: server.statistic.tracks_amount,
            daily_tracks_length: Dusic.format_seconds(server.today_statistic.tracks_length),
            daily_tracks_amount: server.today_statistic.tracks_amount,
            today:               server.today_statistic.date.to_s("%d.%m.%y"),
          }),
          "success"
        )
      end
    end
  end
end
