# frozen_string_literal: true

module Xikolo
  module Model
    class PreferenceRepository
      VALID_BOOLEAN_PREFERENCES = %w[
        notification.email.news.announcement
        notification.email.pinboard.new_answer
        notification.platform.news.announcement
        notification.platform.pinboard.new_answer
        notification.email.global
        records.show_birthdate
        notification.email.stats
      ].freeze

      VALID_INTEGER_PREFERENCES = %w[
        ui.hints.video_player_keyhint
      ].freeze

      VALID_PREFERENCES = %w[
        ui.video.video_player_speed
        ui.video.video_player_volume
        ui.video.video_player_caption_language
        ui.video.video_player_show_captions
        ui.video.video_player_show_transcript
        ui.video.video_player_quality
        ui.video.video_player_ratio
        ui.video.video_dual_stream
      ].freeze

      def find_all(user_id)
        preferences = Xikolo::Account::Preferences.find(user_id:)
        Acfs.run

        preferences.properties.map {|prop| decorate(prop) }
      end

      def find_one(user_id, key)
        find_all(user_id).find(method(:not_found)) {|item| item[:id] == key }
      end

      def set(user_id, key, value)
        if VALID_BOOLEAN_PREFERENCES.include? key
          save_preference user_id, key, value == 'true'
        elsif VALID_INTEGER_PREFERENCES.include? key
          save_preference user_id, key, value.to_i
        elsif VALID_PREFERENCES.include? key
          save_preference user_id, key, value.to_s
        else
          invalid_value
        end
      end

      private

      def decorate(item)
        {
          id: item[0],
          value: item[1],
        }
      end

      def save_preference(user_id, key, value)
        preferences = Xikolo::Account::Preferences.find(user_id:)
        Acfs.run

        preferences.set key, value
        preferences.save!
      end

      def not_found
        raise Xikolo::Error::NotFound.new
      end

      def invalid_value
        raise Xikolo::Error::InvalidValue.new
      end
    end
  end
end
