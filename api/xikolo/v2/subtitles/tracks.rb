# frozen_string_literal: true

module Xikolo
  module V2::Subtitles
    class Tracks < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'subtitle-tracks'

        attribute('language') {
          description 'The subtitle language'
          type :string
        }

        attribute('created_by_machine') {
          description 'Whether the subtitles were created by a machine (or human if not)'
          type :boolean
          alias_for 'automatic'
        }

        attribute('vtt_url') {
          description 'URL to the corresponding WebVTT file'
          type :string
          reading {|subtitle|
            Xikolo::V2::URL.subtitle_url subtitle['id']
          }
        }

        has_one('video', Xikolo::V2::CourseItems::Videos) {
          foreign_key 'video_id'
        }

        includable has_many('cues', Xikolo::V2::Subtitles::Cues) {
          filter_by 'track'
        }
      end

      filters do
        required('video') {
          description 'Only return subtitles belonging to the video with this UUID'
          alias_for 'video_id'
        }
        optional('language') {
          description 'Only return subtitles with this language'
        }
      end

      collection do
        get 'List all subtitles for video' do
          # we request the video endpoint here, because it only returns the subtitle
          # meta data and not the actual content, to reduce the data transfer size
          video = ::Video::Video.find filters['video_id']
          video.subtitles.tap do |subtitles|
            subtitles.where!(lang: filters['language']) if filters.key?('language')
          end.map(&:as_api_v2)
        end
      end
    end
  end
end
