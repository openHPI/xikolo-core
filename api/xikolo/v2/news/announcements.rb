# frozen_string_literal: true

module Xikolo
  module V2::News
    class Announcements < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'announcements'

        attribute('title') {
          description 'The announcement\'s headline'
          type :string
        }

        attribute('text') {
          description 'The announcement\'s content, in Markdown format'
          type :string
        }

        attribute('image_url') {
          description 'URL to the announcement image, if available'
          type :string
          alias_for 'visual_url'
        }

        attribute('published_at') {
          description 'Time of publication'
          type :datetime
          alias_for 'publish_at'
        }

        writable attribute('visited') {
          description 'Whether the announcement has been seen by the current user'
          type :boolean
          alias_for 'read'
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        link('self') {|announcement| "/api/v2/announcements/#{announcement['id']}" }
      end

      filters do
        optional('course') {
          description 'Only return announcements belonging to the course with this UUID'
          alias_for 'course_id'
        }

        optional('global') {
          description 'Include global announcements'
        }

        optional('language') {
          description 'Load the announcements in this language (falls back to the default language if a translation is not available)'
        }
      end

      paginate!

      collection do
        get 'Retrieve latest announcements' do
          block_courses_by('course_id') do
            Xikolo.api(:news).value!.rel(:news_index).get(
              {'published' => true}.tap {|hash|
                if current_user.logged_in?
                  hash['language'] = current_user.preferred_language
                  hash['user_id'] = current_user.id
                else
                  hash['global'] = true
                end
              }.merge(filters),
              headers: {'Accept' => 'application/msgpack, application/json'}
            ).value!
          end
        end
      end

      member do
        get 'Retrieve announcement details' do
          Xikolo.api(:news).value!.rel(:news).get(id:).value!
        end

        patch 'Change article information' do |entity|
          authenticate!

          news_service = Xikolo.api(:news).value!
          announcement = news_service.rel(:news).get(id:).value!

          if entity.to_resource['read']
            announcement.rel(:user_visit).patch(
              {},
              {user_id: current_user.id}
            ).value!
          end

          announcement.to_hash.merge('read' => true)
        end
      end
    end
  end
end
