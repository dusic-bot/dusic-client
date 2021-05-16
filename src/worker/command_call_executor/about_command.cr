require "./base"

class Worker
  class CommandCallExecutor
    class AboutCommand < Base
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
