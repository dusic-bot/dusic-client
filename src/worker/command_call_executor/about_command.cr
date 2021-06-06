require "./command"

class Worker
  class CommandCallExecutor
    class AboutCommand < Command
      def execute
        reply(
          t("commands.about.title"),
          t("commands.about.text", {version: Dusic::VERSION, shard: @worker.shard_id}),
          "success"
        )
      end
    end
  end
end
