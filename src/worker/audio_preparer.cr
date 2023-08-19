class Worker
  # Prepare audios for playback
  class AudioPreparer
    AUDIO_AWAIT_TIMEOUT        = 20.seconds
    AUDIO_AWAIT_CHECK_INTERVAL = 1.second
    MAX_AUDIO_DURATION         = 20.minutes

    Log = Worker::Log.for("audio_preparer")

    def initialize(@worker : Worker)
    end

    def prepare(audio : AudioPlayer::Audio) : Nil
      case audio.status
      when AudioPlayer::Audio::Status::NotReady
        prepare_unready_audio(audio)
      when AudioPlayer::Audio::Status::Loading
        await_loading_audio(audio)
      when AudioPlayer::Audio::Status::Destroyed
        # NOTE: doing nothing; audio destroyed
      when AudioPlayer::Audio::Status::Ready
        # NOTE: doing nothing; audio is prepared
      end
    rescue exception
      Log.error(exception: exception) { "failed loading #{audio}" }
    end

    # NOTE: timeout is around 40 seconds (determined by api_client/http_client)
    private def prepare_unready_audio(audio : AudioPlayer::Audio) : Nil
      case audio
      when AudioPlayer::AssetAudio
        # NOTE: doing nothing
      when AudioPlayer::RemoteAudio
        prepare_remote_audio(audio)
      end
    end

    private def prepare_remote_audio(audio : AudioPlayer::RemoteAudio) : Nil
      # NOTE: currently not attempting to load long audios
      if audio.duration > MAX_AUDIO_DURATION
        audio.destroy
        return
      end

      # NOTE: always VK
      audio.load { @worker.hudba_client.audio_file(audio.id, "dca") }
    end

    private def await_loading_audio(audio : AudioPlayer::Audio) : Nil
      Dusic.await(AUDIO_AWAIT_TIMEOUT, AUDIO_AWAIT_CHECK_INTERVAL) do
        audio.status != AudioPlayer::Audio::Status::Loading
      end
    end
  end
end
