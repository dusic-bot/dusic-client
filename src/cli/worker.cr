require "option_parser"
require "../worker"

shard_id : Int32 = 0
shard_num : Int32 = 1

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: ENV=development worker [options]"
  parser.on "-h", "--help", "Show help message" do
    puts parser
    exit
  end
  parser.on "-i SHARD_ID", "--id SHARD_ID", "id of the Discord shard" { |arg| shard_id = arg.to_i32 }
  parser.on "-n SHARD_NUM", "--id SHARD_NUM", "number of Discord shards" { |arg| shard_num = arg.to_i32 }
end
parser.parse

puts <<-TEXT
  => Booting worker
  => Dusic v#{Dusic::VERSION} client starting in #{Dusic.env}
  => Run `#{PROGRAM_NAME} --help` for more startup options

  *  Environment: #{Dusic.env}
  *          PID: #{Process.pid}

  >     Shard id: #{shard_id}
  >    Shard num: #{shard_num}
  Use Ctrl-C to stop


  TEXT

# Save PID
pid_path = "tmp/pids/worker_#{shard_id}_#{shard_num}"
File.write(pid_path, Process.pid)

# Initialize worker
worker = Worker.new(shard_id, shard_num)

# Capture stop signals
Signal::INT.trap { |sig| worker.stop }
Signal::STOP.trap { |sig| worker.stop }

# Start worker
worker.run

# Clear PID
File.delete(pid_path)
