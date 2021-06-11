class Worker
  # Handle audio selections
  class AudioSelectionsStorage
    Log = Worker::Log.for("audio_selections_storage")

    getter audio_selections : Hash(UInt64, Hash(UInt64, AudioSelection))

    def initialize(@worker : Worker)
      @audio_selections = Hash(UInt64, Hash(UInt64, AudioSelection)).new do |hash, key|
        hash[key] = Hash(UInt64, AudioSelection).new
      end
    end

    def []?(server_id : UInt64, user_id : UInt64) : AudioSelection?
      @audio_selections[server_id][user_id]?
    end

    def []=(server_id : UInt64, user_id : UInt64, audio_selection : AudioSelection) : AudioSelection
      @audio_selections[server_id][user_id] = audio_selection
    end

    def delete(server_id : UInt64, user_id : UInt64) : AudioSelection?
      @audio_selections[server_id].delete(user_id)
    end

    def delete(audio_selection : AudioSelection) : AudioSelection?
      delete(audio_selection.server_id, audio_selection.user_id)
    end
  end
end
