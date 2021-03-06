require "http/client"
require "json"
require "uri"

class Worker
  class ApiClient
    class WebsocketClient
      alias MessageHandler = Hash(String, JSON::Any) -> Nil
      Log = Worker::ApiClient::Log.for("ws")

      RECONNECT_INTERVAL = 30.seconds

      @is_running : Bool = false
      @do_reconnect : Bool = true
      @host : String = Dusic.secrets["api"]["host"].as_s
      @use_ssl : Bool = Dusic.secrets["api"]["ssl"].as_bool
      @headers : HTTP::Headers = HTTP::Headers{
        "Authorization" => "Bearer #{Dusic.secrets["api"]["token"].as_s}",
        "Origin"        => "app://dusic-client",
      }
      @ws_client : HTTP::WebSocket? = nil
      @bot_id : UInt64 = Dusic.secrets["bot_id"].as_s.to_u64
      @handlers : Hash(String, MessageHandler) = {} of String => MessageHandler

      def initialize(@worker : Worker)
      end

      def run : Nil
        @do_reconnect = true
        Dusic.spawn do
          while @do_reconnect
            connect
            if @do_reconnect
              Log.info { "attempting reconnect in 30 seconds" }
              sleep RECONNECT_INTERVAL
            end
          end
        end
      end

      def stop : Nil
        @do_reconnect = false
        disconnect
      end

      def on(channel : String, &block : MessageHandler) : Nil
        identifier = "{\"channel\":\"#{channel}\"}"
        @handlers[identifier] = block
      end

      def message(channel : String, data : String)
        send_json do |json|
          json.object do
            json.field "command", "message"
            json.field "identifier", "{\"channel\":\"#{channel}\"}"
            json.field "data", data
          end
        end
      end

      private def connect : Nil
        Log.warn { "client exists!" } if @ws_client

        Log.info { "connecting" }

        ws_client = HTTP::WebSocket.new(uri, @headers)
        ws_client.on_close(&->on_close(HTTP::WebSocket::CloseCode, String))
        ws_client.on_message(&->on_message(String))

        @is_running = true
        @ws_client = ws_client
        ws_client.run
      rescue Channel::ClosedError
        # NOTE: Worker stopped and closed the channel
      rescue exception
        Log.error(exception: exception) { "connection error" }
      ensure
        @ws_client = nil
        @is_running = false
      end

      private def disconnect : Nil
        Log.warn { "client does not exist!" } if @ws_client.nil?

        Log.info { "disconnecting" }
        @ws_client.try &.close
        Log.info { "disconnected" }
      rescue exception
        Log.error(exception: exception) { "disconnecting error" }
      ensure
        @ws_client = nil
        @is_running = false
      end

      private def send(msg : String) : Nil
        Log.debug { "outgoing message: #{msg}" }
        @ws_client.try &.send(msg)
      end

      private def send_json(&block : JSON::Builder -> Nil) : Nil
        json_string = JSON.build(&block)
        send(json_string)
      end

      private def send_subscribe(identifier : String) : Nil
        send_json do |json|
          json.object do
            json.field "command", "subscribe"
            json.field "identifier", identifier
          end
        end
      end

      private def on_close(code : HTTP::WebSocket::CloseCode, msg : String) : Nil
        Log.info { "closed (#{code}): #{msg}" }
      end

      private def on_message(msg : String) : Nil
        Log.debug { "incoming message: #{msg}" }

        handle_message(msg)
      end

      private def uri : URI
        uri = URI.parse("#{@use_ssl ? "wss" : "ws"}://#{@host}/ws")
        uri.query = "shard_id=#{@worker.shard_id}&shard_num=#{@worker.shard_num}&bot_id=#{@bot_id}"
        uri
      end

      private def handle_message(msg : String) : Nil
        json = JSON.parse(msg)
        type = json["type"]?.try &.as_s || "channel_message"

        case type
        when "welcome"
          @handlers.keys.each { |channel| send_subscribe(channel) }
        when "ping"
          # NOTE: do nothing
        when "confirm_subscription"
          # NOTE: that's good
        when "channel_message"
          handle_channel_message(json)
        else
          Log.warn { "unknown message type #{type}" }
        end
      rescue exception
        Log.error(exception: exception) { "message handling failed" }
      end

      private def handle_channel_message(json : JSON::Any) : Nil
        identifier = json["identifier"].as_s
        message = json["message"].as_h

        handler = @handlers[identifier]?
        if handler
          handler.call(message)
        else
          Log.warn { "handler undefined for #{identifier}" }
        end
      rescue exception
        Log.error(exception: exception) { "channel message handling failed" }
      end
    end
  end
end
