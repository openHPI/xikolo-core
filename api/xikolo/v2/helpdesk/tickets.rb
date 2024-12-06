# frozen_string_literal: true

module Xikolo
  module V2::Helpdesk
    class Tickets < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'tickets'

        writable attribute('title') {
          description 'The title of the ticket. Required for POST.'
          type :string
        }

        writable attribute('report') {
          description 'The description of the ticket. Required for POST.'
          type :string
        }

        writable attribute('topic') {
          description 'The topic of the ticket, either technical, reactivation, or course. If course, a relationship must be passed as well. Required for POST.'
          type :string
        }

        writable attribute('language') {
          description 'The language of the user\'s client. Required for POST.'
          type :string
        }

        writable attribute('mail') {
          description 'The user\'s email. Required for POST if no authorization header is sent, otherwise ignored and extracted automatically.'
          type :string
        }

        writable attribute('url') {
          description 'An optional URL.'
          type :string
        }

        writable attribute('data') {
          description 'An optional data string, usually some client information formatted as a user-agent.'
          type :string
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }
      end

      collection do
        post 'Store helpdesk tickets' do |entity|
          res = entity.to_resource

          if current_user.authenticated?
            res['user_id'] = current_user.id
            res['mail'] = current_user.email
          end

          ::Helpdesk::Ticket.create!(res)
        rescue ActiveRecord::RecordInvalid
          raise Xikolo::Error::UnprocessableEntity
        end
      end
    end
  end
end
