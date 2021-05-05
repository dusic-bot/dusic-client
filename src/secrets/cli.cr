require "option_parser"

environment : String = "development"

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: EDITOR=vim secrets [options]"
  parser.on "-h", "--help", "Show help message" do
    puts parser
    exit
  end
  parser.on "-e ENV", "--environment ENV", "Specify target environment (default: 'development')" { |arg| environment = arg }
end
parser.parse

puts "TODO: #{environment}"
