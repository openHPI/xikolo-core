# frozen_string_literal: true

module Xikolo
  module V2::Pinboard
    class Topics < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'pinboard-topics'

        writable attribute('title') {
          description 'The title of the topic'
          type :string
        }

        writable attribute('abstract') {
          description 'The abstract of the topic'
          type :string
        }

        attribute('created_at') {
          description 'The timestamp at which the topic was created'
          type :datetime
        }

        attribute('reply_count') {
          description 'The number of replies to a topic'
          alias_for 'num_replies'
          type :integer
        }

        attribute('closed') {
          description 'The state of the topic (boolean)'
          type :boolean
        }

        writable attribute('meta') {
          description 'Meta information about the topic (e.g. the video timestamp)'
          type :hash
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        has_one('item', Xikolo::V2::Courses::Items) {
          foreign_key 'item_id'
        }

        link('self') {|topic| "/api/v2/pinboard-topics/#{topic['id']}" }
      end

      filters do
        required('item') {
          description 'Only return topics belonging to the item with this UUID'
          alias_for 'item_id'
        }
      end

      collection do
        get 'List all topics' do
          authenticate!

          Restify::Promise.new([
            Xikolo.api(:course).value!.rel(:item).get({id: filters['item_id']}),
            Xikolo.api(:pinboard).value!.rel(:topics).get(filters),
          ]) do |item, topics|
            topics.each {|topic|
              topic['item_id'] = item[:id]
              topic['course_id'] = item[:course_id]
            }
          end.value!
        end

        post 'Create a topic' do |entity|
          authenticate!

          resource = entity.to_resource

          Xikolo.api(:pinboard).value!.rel(:topics).post({
            title: resource['title'],
            first_post: {text: resource['abstract']},
            meta: {video_timestamp: resource['meta']['video_timestamp']},
            author_id: current_user.id,
            course_id: resource['course_id'],
            item_id: resource['item_id'],
          }).value!.tap {|topic|
            topic['course_id'] = resource['course_id']
            topic['item_id'] = resource['item_id']
          }
        end
      end
    end
  end
end
