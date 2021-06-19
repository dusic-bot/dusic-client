require "yaml"
require "log"

class Cluster
  alias WorkerData = NamedTuple(env: String, shard_id: Int32, shard_num: Int32, log: String)

  Log = ::Log.for("cluster")

  @workers : Array(WorkerData) = [] of WorkerData

  def initialize(config_path : String)
    load_configuration(config_path)
  end

  def run : Nil
    Log.info { "Starting cluster" }

    # TODO
  end

  def stop : Nil
    Log.info { "Stopping cluster" }

    # TODO
  end

  private def load_configuration(config_path : String) : Nil
    Log.debug { "Loading configuration from #{config_path}" }

    config = YAML.parse(File.read(config_path))
    config["workers"].as_a.each do |worker_config|
      @workers << parse_worker_configuration(worker_config)
    end

    Log.info { "Loaded configuration for #{@workers.size} workers" }
  end

  private def parse_worker_configuration(worker_config : YAML::Any) : WorkerData
    {
      env: worker_config["log"].as_s,
      shard_id: worker_config["shard_id"].as_i,
      shard_num: worker_config["shard_num"].as_i,
      log: worker_config["log"].as_s
    }
  end
end
