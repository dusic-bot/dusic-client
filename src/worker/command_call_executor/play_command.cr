require "./command"

class Worker
  class CommandCallExecutor
    class PlayCommand < Command
      include Command::WithAudiosAddition

      YOUTUBE_VIDEO_ID_REGEX = /(?:https?:\/\/)?(?:www\.)?youtu(?:\.be\/|be.com\/\S*(?:watch|embed)(?:(?:(?=\/[^&\s\?]+(?!\S))\/)|(?:\S*v=|v\/)))([^&\s\?]+)/i
      VK_URL_REGEX           = /(?:https?:\/\/)?(?:www\.)?(?:vk|vkontakte)\.(?:com|ru)\//i
      SELECTION_SIZE         = 10

      ASSETS_LIST = {
        rickroll:        AudioPlayer::AssetAudio.new("rickroll", "Rick Astley", "Never Gonna Give You Up", 211_u32),
        dj_watermelon:   AudioPlayer::AssetAudio.new("dj_watermelon", "DJ", "Арбуз", 6_u32),
        cornfield_chase: AudioPlayer::AssetAudio.new("cornfield_chase", "Hanz Zimmer", "Cornfield Chase", 127_u32),
        boomer_violin:   AudioPlayer::AssetAudio.new("boomer_violin", "Бумер", "Скрипка", 28_u32),
        mario_death:     AudioPlayer::AssetAudio.new("mario_death", "Mario", "Death", 5_u32),
      }

      enum Manager
        None
        Asset
        Youtube
        Vk
      end

      def execute : Nil
        manager = determine_manager
        apply_audios_addition_option_aliases!

        if manager == Manager::None
          if audio_player.queue.empty?
            reply(t("commands.play.title"), t("audio_player.text.queue_is_empty"), "warning")
          else
            audio_player.play
          end

          return
        end

        if audio_player.queue.full?
          reply(t("commands.play.title"), t("audio_player.text.queue_is_full"), "warning")
          return
        end

        audios, title = fetch_audios_and_title(manager)
        return if audios.nil?

        if audios.empty?
          reply(t("commands.play.title"), t("commands.play.text.nothing_found"), "warning")
          return
        end

        space_left = audio_player.queue.limit - audio_player.queue.size
        if audios.size > space_left
          audios = audios.first(space_left)
          reply(t("commands.play.title"), t("audio_player.text.queue_limit_hit"), "warning")
        end

        add_and_play(audios, title)
      end

      private def determine_manager : Manager
        arguments = @command_call.arguments
        options = @command_call.options

        if arguments.empty?
          Manager::None
        elsif options.has_key?("asset")
          Manager::Asset
        elsif options.has_key?("youtube") || options.has_key?("yt")
          Manager::Youtube
        elsif options.has_key?("vkontakte") || options.has_key?("vk")
          Manager::Vk
        else
          argument = arguments.join(' ')
          if youtube_video?(argument)
            Manager::Youtube
          elsif vk_url?(argument)
            Manager::Vk
          else
            Manager::Vk
          end
        end
      end

      private def youtube_video?(url : String) : Bool
        youtube_video_id : String? = if match = url.match(YOUTUBE_VIDEO_ID_REGEX)
          match[1]?
        else
          nil
        end

        !youtube_video_id.nil?
      end

      private def vk_url?(url : String) : Bool
        vk_url : String? = if match = url.match(VK_URL_REGEX)
          match[0]
        else
          nil
        end

        !vk_url.nil?
      end

      private def find_asset : AudioPlayer::AssetAudio?
        name = @command_call.arguments.join("_").downcase

        case name
        when "rickroll", "rick_roll"
          ASSETS_LIST[:rickroll]
        when "dj_watermelon", "dj", "watermelon", "arbuz"
          ASSETS_LIST[:dj_watermelon]
        when "cornfield_chase"
          ASSETS_LIST[:cornfield_chase]
        when "violin", "boomer", "boomer_violin", "violin_boomer"
          ASSETS_LIST[:boomer_violin]
        when "mario_death"
          ASSETS_LIST[:mario_death]
        else
          nil
        end
      end

      private def fetch_audios_and_title(manager : Manager) : Tuple(Array(AudioPlayer::Audio)?, String?)
        case manager
        when Manager::Asset   then fetch_asset_audios
        when Manager::Youtube then fetch_yt_audios
        when Manager::Vk      then fetch_vk_audios
        else                       {[] of AudioPlayer::Audio, nil}
        end
      end

      private def fetch_asset_audios : Tuple(Array(AudioPlayer::Audio)?, String?)
        array = [] of AudioPlayer::Audio
        asset = find_asset
        if asset
          array << asset
        end
        {array, nil}
      end

      private def fetch_yt_audios : Tuple(Array(AudioPlayer::Audio)?, String?)
        reply(t("commands.play.title"), t("commands.play.errors.yt_unavailable"), "danger")
        {nil, nil}
      end

      private def fetch_vk_audios : Tuple(Array(AudioPlayer::Audio)?, String?)
        argument = @command_call.arguments.join(" ")
        audio_request = @worker.api_client.vk_audios(argument)

        title : String? = nil
        if audio_request.response.size == 1 && audio_request.response.first.is_a?(ApiClient::Mapping::AudioList)
          title = audio_request.response.first.title
        end

        audios = [] of AudioPlayer::Audio
        audio_request.response.map do |el|
          el.is_a?(ApiClient::Mapping::Audio) ? el : el.audios
        end.flatten.each do |el|
          manager = el.manager
          id = el.id
          if manager && id
            audios << AudioPlayer::RemoteAudio.new(manager, id, el.artist, el.title, el.duration)
          end
        end

        if audio_request.type == "find" && @command_call.options.has_key?("instant")
          {audios[0, 1], title}
        elsif audio_request.type == "find"
          init_vk_selection(audios)
          {nil, title}
        else
          {audios, title}
        end
      end

      private def init_vk_selection(audios : Array(AudioPlayer::Audio)) : Nil
        body = String::Builder.new
        selection_audios = audios.first(SELECTION_SIZE)

        if selection_audios.empty?
          body << t("commands.play.text.nothing_found")
        else
          selection_audios.each_with_index(1) do |audio, index|
            body << t("commands.play.text.find_line", {
              index:    index,
              artist:   audio.artist,
              title:    audio.title,
              duration: Dusic.format_seconds(audio.duration),
            }) << "\n"
          end
          body << "\n" << t("commands.play.text.find_footer")
        end

        find_message_id = reply(t("commands.play.title"), body.to_s, "success")

        audio_selection = AudioSelection.new(
          @command_call.server_id,
          @command_call.author_id,
          @command_call.channel_id,
          find_message_id,
          selection_audios
        )
        @worker.audio_selections_storage[@command_call.server_id, @command_call.author_id] = audio_selection
      end
    end
  end
end
