# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class Channels < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'channels'

        id {|channel| channel['code'] }

        attribute('title') {
          description 'The public title of this channel'
          alias_for 'name'
          type :string
        }

        # @deprecated
        attribute('color') {
          version max: 4
          description 'Hexadecimal RGB color values as known from CSS, e.g. FF0000 for red'
          type :string
          reading { Xikolo.config.ui_primary_color }
        }

        attribute('position') {
          description 'Relative position in the channel list'
          type :integer
        }

        attribute('description') {
          description 'A localized long-form text describing the channel contents in greater detail. Picks an available language based on the Accept-Language header.'
          type :string
        }

        attribute('mobile_image_url') {
          description 'URL to the mobile-friendly channel image'
          type :string
          reading {|channel|
            next if channel['mobile_visual_url'].blank?

            channel['mobile_visual_url']
          }
        }

        member_only attribute('stage_logo_url') {
          description 'URL to the channel logo'
          type :string
          reading {|channel|
            next if channel['logo_url'].blank?

            channel['logo_url']
          }
        }

        member_only attribute('stage_image_url') {
          description 'URL to the stage image'
          type :string
          reading {|channel|
            next if channel['stage_visual_url'].blank?

            Imagecrop.transform(channel['stage_visual_url'])
          }
        }

        member_only attribute('stage_statement') {
          description 'A short text describing the channel contents'
          type :string
        }

        # @deprecated
        member_only attribute('stage_stream') {
          version max: 4
          description 'Media info about the stage stream, if it exists'
          type :hash, of: Xikolo::V2::VideoStream.schema
          reading { nil }
        }

        includable has_many('courses', Xikolo::V2::Courses::Courses) {
          filter_by 'channel'
        }

        link('self') {|channel| "/api/v2/channels/#{channel['id']}" }
      end

      collection do
        get 'List all channels on this platform' do
          Xikolo.api(:course).value.rel(:channels).get({
            public: true,
          }).value!.each {|channel|
            channel['description'] = Xikolo::V2::Courses::Channels.description_for_language(channel['description'], accept_language)
          }
        end
      end

      member do
        get 'Retrieve information about a channel' do
          Xikolo.api(:course).value.rel(:channel).get({id:}).value!.tap {|channel|
            channel['description'] = Xikolo::V2::Courses::Channels.description_for_language(channel['description'], accept_language)
          }
        end
      end

      def self.description_for_language(description, accept_language)
        return if description.nil?

        [
          Xikolo.config.locales['default'],
          *Xikolo.config.locales['available'],
          accept_language,
        ].compact.each do |locale|
          return description[locale.to_s] if description.key? locale.to_s
        end
      end
    end
  end
end
