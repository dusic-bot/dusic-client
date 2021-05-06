require "option_parser"
require "../dusic_client"

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
  => Dusic v#{DusicClient::VERSION} client starting in #{DusicClient.env}
  => Run `#{PROGRAM_NAME} --help` for more startup options

  *  Environment: #{DusicClient.env}
  *          PID: #{Process.pid}

  >     Shard id: #{shard_id}
  >    Shard num: #{shard_num}
  Use Ctrl-C to stop
  TEXT

# TODO
