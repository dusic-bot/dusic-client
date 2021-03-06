class Worker
  # Single audio selection
  class AudioSelection
    getter server_id : UInt64
    getter user_id : UInt64
    getter channel_id : UInt64
    getter message_id : UInt64?
    getter audios : Array(AudioPlayer::Audio)

    def initialize(
      @server_id : UInt64,
      @user_id : UInt64,
      @channel_id : UInt64,
      @message_id : UInt64?,
      @audios : Array(AudioPlayer::Audio)
    )
    end

    def fetch(indexes : Array(Int32)) : Array(AudioPlayer::Audio)
      result = Array(AudioPlayer::Audio).new
      indexes.each do |i|
        if audio = @audios[i]?
          result.push(audio)
        end
      end
      result
    end
  end
end
