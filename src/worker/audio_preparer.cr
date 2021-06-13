class Worker
  # Prepare audios for playback
  class AudioPreparer
    Log = Worker::Log.for("audio_preparer")

    def initialize(@worker : Worker)
    end

    # NOTE: timeout is around 40 seconds (determined by api_client/http_client)
    def prepare(audio : AudioPlayer::Audio)
      sleep 2.seconds # TODO: call audio prepare algorithm
    end
  end
end
