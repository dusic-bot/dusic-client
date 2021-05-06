require "option_parser"

require "../secrets"

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

unless ENV.has_key?("EDITOR")
  puts <<-TEXT
    No $EDITOR to open file in. Assign one like this:

    EDITOR=vim #{PROGRAM_NAME}
    EDITOR="mate --wait" #{PROGRAM_NAME}

    For editors that fork and exit immediately, it's important to pass a wait flag,
    otherwise the credentials will be saved immediately with no chance to edit.
    TEXT
  exit
end

data = Secrets.read(environment).chomp
tempfile = File.tempfile(environment, ".yml")
tempfile.puts(data)
tempfile.flush
system(ENV["EDITOR"], [tempfile.path])
tempfile.rewind
new_data : String = tempfile.gets_to_end
tempfile.delete
Secrets.write(new_data, environment)
