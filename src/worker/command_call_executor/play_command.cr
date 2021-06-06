require "./command"

class Worker
  class CommandCallExecutor
    class PlayCommand < Command
      YOUTUBE_VIDEO_ID_REGEX = /(?:https?:\/\/)?(?:www\.)?youtu(?:\.be\/|be.com\/\S*(?:watch|embed)(?:(?:(?=\/[^&\s\?]+(?!\S))\/)|(?:\S*v=|v\/)))([^&\s\?]+)/i
      VK_URL_REGEX           = /(?:https?:\/\/)?(?:www\.)?(?:vk|vkontakte)\.(?:com|ru)\//i

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

      def execute
        manager = determine_manager
        apply_option_aliases!

        if manager == Manager::None
          if audio_player.queue.empty?
            reply(t("commands.play.title"), t("audio_player.text.queue_is_empty"), "warning")
          else
            resume_playback
          end

          return
        end

        if audio_player.queue.full?
          reply(t("commands.play.title"), t("audio_player.text.queue_is_full"), "warning")
          return
        end

        title, audios = titled_audios_to_add(manager)

        if audios.empty?
          reply(t("commands.play.title"), t("commands.play.text.nothing_found"), "warning")
          return
        end

        space_left = audio_player.queue.limit - audio_player.queue.size
        if audios.size > space_left
          audios = audios.first(space_left)
          reply(t("commands.play.title"), t("audio_player.text.queue_limit_hit"), "warning")
        end

        audios.shuffle! if @command_call.options.has_key?("shuffle")

        if @command_call.options.has_key?("skip")
          # TODO: skip current track
        end

        if @command_call.options.has_key?("first")
          audio_player.queue.unshift(audios)
        else
          audio_player.queue.push(audios)
        end

        reply_to_added_audios(audios, title)

        resume_playback
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

      private def apply_option_aliases! : Nil
        options = @command_call.options
        if options.has_key?("now")
          options["first"] = options["skip"] = options["instant"] = nil
        end
      end

      private def titled_audios_to_add(manager) : Tuple(String?, AudioPlayer::AudioArray)
        case manager
        when Manager::Asset
          asset = find_asset
          audios = asset.nil? ? [] of AudioPlayer::Audio : [asset]
          {nil, audios}
        when Manager::Youtube
          audios = [] of AudioPlayer::Audio # TODO
          {nil, audios}
        when Manager::Vk
          audios = [] of AudioPlayer::Audio # TODO
          {nil, audios}
        else
          audios = [] of AudioPlayer::Audio
          {nil, audios}
        end
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

      private def resume_playback : Nil
        audio_player.play # TODO
      end

      private def reply_to_added_audios(audios : AudioPlayer::AudioArray, title : String? = nil) : Nil
        if audios.empty?
          reply(t("commands.play.title"), t("commands.play.text.nothing_found"), "warning")
        elsif audios.size == 1
          reply(
            t("audio_player.title"),
            t("audio_player.text.audio_added", {
              artist:   audios.first.artist,
              title:    audios.first.title,
              duration: Dusic.format_seconds(audios.first.duration),
            }),
            "success"
          )
        elsif title
          reply(
            t("audio_player.title"),
            t("audio_player.text.audio_list_added", {title: title}, count: audios.size),
            "success"
          )
        else
          reply(t("audio_player.title"), t("audio_player.text.audios_added", count: audios.size), "success")
        end
      end
    end
  end
end
