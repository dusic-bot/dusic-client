require "http/client"
require "uri"

class Worker
  class ApiClient
    class HttpClient
      Log = Worker::ApiClient::Log.for("http")

      CONNECTION_TIMEOUT = 5.seconds
      RW_TIMEOUT         = 40.seconds

      @host : String = Dusic.secrets["api"]["host"].as_s
      @use_ssl : Bool = Dusic.secrets["api"]["ssl"].as_bool
      @headers : HTTP::Headers = HTTP::Headers{
        "Authorization" => "Bearer #{Dusic.secrets["api"]["token"].as_s}",
        "Origin"        => "app://dusic-client",
        "Content-Type"  => "application/json",
      }

      def initialize
      end

      def get(subpath : String, body : String? = nil) : String
        get_raw(subpath, body).body
      end

      def put(subpath : String, body : String? = nil) : String
        put_raw(subpath, body).body
      end

      def get_raw(subpath : String, body : String? = nil) : HTTP::Client::Response
        Log.debug { "GET #{subpath}: #{body}" }
        with_client do |client|
          client.get("/api/v2/#{subpath}", headers: @headers, body: body)
        end
      end

      def get_raw(subpath : String, body : String? = nil, &block : HTTP::Client::Response -> Nil) : Nil
        Log.debug { "GET #{subpath}: #{body}" }
        with_client do |client|
          client.get("/api/v2/#{subpath}", headers: @headers, body: body) do |response|
            yield(response)
          end
        end
      end

      def put_raw(subpath : String, body : String? = nil) : HTTP::Client::Response
        Log.debug { "PUT #{subpath}: #{body}" }
        with_client do |client|
          client.put("/api/v2/#{subpath}", headers: @headers, body: body)
        end
      end

      # NOTE: Using single client for all requests might result in races and SSL
      # errors. This method creates unique client and yields it to block. This
      # might be useful for sending several requests consequently from single client
      private def with_client(&block : HTTP::Client ->)
        HTTP::Client.new(uri) do |client|
          client.connect_timeout = client.dns_timeout = CONNECTION_TIMEOUT
          client.read_timeout = client.write_timeout = RW_TIMEOUT
          yield client
        end
      end

      private def uri : URI
        URI.parse("#{@use_ssl ? "https" : "http"}://#{@host}")
      end
    end
  end
end
