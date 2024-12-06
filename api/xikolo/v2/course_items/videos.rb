# frozen_string_literal: true

require 'uuid4'

module Xikolo
  module V2::CourseItems
    class Videos < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'videos'

        attribute('summary') {
          description 'A short description of the video contents'
          alias_for 'description'
          type :string
        }

        attribute('duration') {
          description 'The video\'s duration in seconds, if known'
          type :integer
        }

        attribute('single_stream') {
          description 'Media info about the single stream (picture-in-picture), if it exists. Clients can choose to use this version instead of combining the lecturer and slides streams.'
          type :hash, of: Xikolo::V2::VideoStream.schema
          reading {|video|
            next if video['pip_stream_id'].blank?

            stream = ::Video::Stream.find video['pip_stream_id']
            Xikolo::V2::VideoStream.data stream, video['id']
          }
        }

        attribute('lecturer_stream') {
          description 'Media info about the lecturer stream, if it exists.'
          type :hash, of: Xikolo::V2::VideoStream.schema
          reading {|video|
            next if video['lecturer_stream_id'].blank?

            stream = ::Video::Stream.find video['lecturer_stream_id']
            Xikolo::V2::VideoStream.data stream, video['id']
          }
        }

        attribute('slides_stream') {
          description 'Media info about the slides stream, if it exists.'
          type :hash, of: Xikolo::V2::VideoStream.schema
          reading {|video|
            next if video['slides_stream_id'].blank?

            stream = ::Video::Stream.find video['slides_stream_id']
            Xikolo::V2::VideoStream.data stream, video['id']
          }
        }

        attribute('slides_url') {
          description 'URL to the lecture slides (PDF), if available'
          type :string
        }

        attribute('slides_size') {
          description 'Size of the lecture slides in bytes, if available'
          type :integer
        }

        attribute('audio_url') {
          description 'URL to the audio recording (MP3), if available'
          type :string
        }

        attribute('audio_size') {
          description 'Size of the audio recording in bytes, if available'
          type :integer
        }

        attribute('transcript_url') {
          description 'URL to the video transcript (PDF), if available'
          type :string
        }

        attribute('transcript_size') {
          description 'Size of the video transcript in bytes, if available'
          type :integer
        }

        attribute('thumbnail_url') {
          description 'URL to the thumbnail image that can be shown as a preview'
          type :string
          alias_for 'thumbnail'
        }

        attribute('subtitles') {
          description 'All subtitles for video'

          type :array, of: nested_type(:hash, of: {
            language: :string,
            created_by_machine: :boolean,
            vtt_url: :string,
          })
        }

        includable has_many('subtitle-tracks', Xikolo::V2::Subtitles::Tracks) {
          filter_by 'video'
        }

        link('self') {|video| "/api/v2/videos/#{video['id']}" }
      end

      member do
        get 'Retrieve information about a video' do
          authenticate!

          item = ::Course::Item.find_by(content_id: id)
          course = item&.section&.course
          not_found! unless item&.available? && course.present?

          in_context course.context_id

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          ::Video::Video.find(id).as_api_v2
        end
      end
    end
  end
end
