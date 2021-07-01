require "option_parser"
require "../cluster"

config_path : String? = nil

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: cluster [options]"
  parser.on "-h", "--help", "Show help message" do
    puts parser
    exit
  end
  parser.on "-c CONFIG_PATH", "--config CONFIG_PATH", "path to cluster configuration" { |arg| config_path = arg.to_s }
end
parser.parse

if config_path.nil?
  puts "Fatal: path to cluster configuration not specified"
  exit 1
end

unless File.exists?(config_path.not_nil!)
  puts "Fatal: cluster configuration does not exist"
  exit 1
end

puts <<-TEXT
  => Booting cluster
  => Run `#{PROGRAM_NAME} --help` for more startup options

  * PID: #{Process.pid}

  > Configuration path: #{config_path}
  Use Ctrl-C to stop


  TEXT

# Save PID
pid_path = "tmp/pids/cluster"
File.write(pid_path, Process.pid)

# Initialize cluster
cluster = Cluster.new(config_path.not_nil!)

# Capture stop signals
Signal::INT.trap { |sig| cluster.stop }
Signal::STOP.trap { |sig| cluster.stop }

# Start cluster
cluster.run

# Clear PID
File.delete(pid_path)
