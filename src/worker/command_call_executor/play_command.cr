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
        # TODO: Check whether queue is full

        manager = determine_manager(@command_call.arguments, @command_call.options)
        apply_option_aliases!(@command_call.options)

        if manager == Manager::None
          # TODO: resume playback if there is something in queue
          return
        end

        audios = audios_to_add(manager, @command_call.arguments)

        if audios.empty?
          # TODO: "Nothing found!"
        end

        # TODO: add audios to queue
        # TODO: send reply

        # TODO: resume playback
      end

      private def determine_manager(arguments, options) : Manager
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

      private def apply_option_aliases!(options) : Nil
        if options.has_key?("now")
          options["first"] = options["skip"] = options["instant"] = nil
        end
      end

      private def audios_to_add(manager, arguments) : Array(AudioPlayer::Audio)
        return [] of AudioPlayer::Audio # TODO

        case manager
        when Manager::None
          [] of AudioPlayer::Audio
        when Manager::Asset
          [find_asset(arguments)]
          # TODO
        when Manager::Youtube
          # TODO: Youtube support
        when Manager::Vk
          # TODO
        end
      end

      private def find_asset(arguments) : AudioPlayer::AssetAudio?
        case arguments.join("_").downcase
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
    end
  end
end
