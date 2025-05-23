# frozen_string_literal: true

module Xikolo
  module V2::Activity
    class PlatformEvents < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'platform-events'

        attribute('type') {
          description 'The event type (e.g. pinboard.question.new)'
          alias_for 'key'
          type :string
        }

        attribute('title') {
          description 'A description of the event (formatted as Markdown)'
          type :string
        }

        attribute('preview_html') {
          description 'A short HTML snippet to show as preview of the related content'
          type :string
          reading {|event|
            case event['key']
              when 'pinboard.discussion.comment.new',
                   'pinboard.discussion.new',
                   'pinboard.question.answer.comment.new',
                   'pinboard.question.comment.new',
                   'pinboard.question.answer.new',
                   'pinboard.question.new'
                HtmlTruncator.new.truncate(MarkdownProxy.new.render_markdown(event['text']), max_length: 160)
              else
                MarkdownProxy.new.render_markdown event['text']
            end
          }
        }

        attribute('created_at') {
          description 'The time when the event was logged'
          type :datetime
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        link('html') {|event|
          # Create links manually for some events so we dont have to store too much UI related data in the service
          if %w[pinboard.discussion.new pinboard.question.new].include? event['key']
            "/courses/#{event['payload']['course_code']}/question/#{event['payload']['question_id']}"
          else
            event['link'] || event['payload']['link']
          end
        }
      end

      filters do
        optional('course') {
          alias_for 'course_id'
        }
      end

      paginate!

      collection do
        get 'Returns events for the user, can be filtered to course' do
          authenticate!

          Xikolo.api(:notification).value.rel(:events).get(
            filters.merge(
              'user_id' => current_user.id,
              'locale' => current_user.preferred_language
            )
          ).value!
        end
      end

      class MarkdownProxy
        include MarkdownHelper
      end
    end
  end
end
