require "yaml"
require "log"

require "./cluster/*"

class Cluster
  Log = ::Log.for("cluster")

  @workers : Array(WorkerData) = [] of WorkerData

  def initialize(config_path : String)
    load_configuration(config_path)
  end

  def run : Nil
    Log.info { "Starting cluster" }

    @workers.each do |worker_data|
      start_worker(worker_data)
    end

    @workers.each do |worker_data|
      await_worker(worker_data)
    end
  end

  def stop : Nil
    Log.info { "Stopping cluster" }

    @workers.each do |worker_data|
      stop_worker(worker_data)
    end
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
    WorkerData.new(
      worker_config["env"].as_s,
      worker_config["shard_id"].as_i,
      worker_config["shard_num"].as_i,
      worker_config["log"].as_s
    )
  end

  private def start_worker(worker_data : WorkerData) : Nil
    process = Process.new(
      "bin/worker",
      ["-i", worker_data.shard_id.to_s, "-n", worker_data.shard_num.to_s],
      { "ENV" => worker_data.env },
      output: File.open("log/#{worker_data.log}.log", "w")
    )
    worker_data.process = process

    Log.info { "Started worker with PID #{worker_data.pid}" }
  end

  private def await_worker(worker_data : WorkerData) : Nil
    if process = worker_data.process
      pid = process.pid
      process.wait

      Log.info { "Worker with PID #{pid} finished" }
    else
      Log.warn { "Skipping worker since process is nil" }
    end
  end

  private def stop_worker(worker_data : WorkerData) : Nil
    if pid = worker_data.pid
      Process.signal(Signal::INT, pid)

      Log.info { "Stopped worker with PID #{pid}" }
    else
      Log.warn { "Skipping worker since process is nil" }
    end
  end
end
