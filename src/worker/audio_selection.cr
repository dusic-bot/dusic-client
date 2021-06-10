class Worker
  # Single audio selection
  class AudioSelection
    getter server_id : UInt64
    getter user_id : UInt64
    getter message_id : UInt64?
    getter audios : Array(AudioPlayer::Audio)

    def initialize(
      @server_id : UInt64,
      @user_id : UInt64,
      @message_id : UInt64?,
      @audios : Array(AudioPlayer::Audio)
    )
    end
  end
end
