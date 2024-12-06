# frozen_string_literal: true

module Xikolo
  module V2::Subtitles
    class Cues < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'subtitle-cues'

        id {|cue| cue['id'] }

        attribute('identifier') {
          description 'The cue identifier, mainly used as position for ordering'
          type :string
        }

        attribute('text') {
          description 'The actual text of the subtitle cue'
          type :string
        }

        attribute('start') {
          description 'The start time of the subtitle cue'
          type :string
        }

        attribute('end') {
          description 'The end time of the subtitle cue'
          type :string
        }

        attribute('settings') {
          description 'The display configuration of the subtitle cue'
          type :string
        }
      end

      filters do
        required('track') {
          description 'Only return subtitle cues belonging to the subtitle track with this UUID'
          alias_for 'track_id'
        }
      end

      collection do
        get 'List all subtitle cues for video' do
          ::Video::Subtitle.find(filters['track_id']).cues.map(&:as_api_v2)
        end
      end
    end
  end
end
