class Cluster
  class WorkerData
    getter env : String
    getter shard_id : Int32
    getter shard_num : Int32
    getter log : String
    property process : Process?

    def initialize(@env, @shard_id, @shard_num, @log)
      @process = nil
    end

    def pid : Int64?
      @process.try &.pid
    end
  end
end
