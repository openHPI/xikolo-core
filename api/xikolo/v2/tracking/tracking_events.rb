# frozen_string_literal: true

module Xikolo
  module V2::Tracking
    class TrackingEvents < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'tracking-events'

        writable attribute('user') {
          description 'A hash describing the user causing this event. Required keys: uuid - the user\'s UUID.'
          type :hash, of: {uuid: :string}
        }

        writable attribute('verb') {
          description 'A hash describing the kind of action that is being tracked. Required keys: type - one of the predefined constants, e.g. VIDEO_PLAY.'
          type :hash, of: {type: :string}
        }

        writable attribute('resource') {
          description 'A hash describing the object that was acted upon. Required keys: type, uuid.'
          type :hash, of: {uuid: :string, type: :string}
        }

        writable attribute('timestamp') {
          description 'Full date and time of the event. Example: 2015-09-24T10:06:49+02:00'
          type :datetime
        }

        writable attribute('result') {
          description 'A hash of information describing the result of the action that was executed. Arbitrary keys allowed.'
          type :hash
        }

        writable attribute('context') {
          description 'A hash of additional context information relevant to this element. Arbitrary keys allowed.'
          type :hash
        }
      end

      collection do
        post 'Store tracking events' do |entity|
          authenticate!

          json = entity.to_resource

          begin
            raise ArgumentError.new 'user -> uuid cannot be blank' if json.dig('user', 'uuid').blank?
            raise ArgumentError.new 'verb -> type cannot be blank' if json.dig('verb', 'type').blank?
            raise ArgumentError.new 'resource -> uuid cannot be blank' if json.dig('resource', 'uuid').blank?
            raise ArgumentError.new 'resource -> type cannot be blank' if json.dig('resource', 'type').blank?

            exp_api_stmt = {
              user:        json['user'],
              verb:        json['verb'],
              resource:    json['resource'],
              timestamp:   json['timestamp'] || DateTime.now.iso8601(3),
              with_result: json.fetch('result', {}),
              in_context:  json.fetch('context', {}).tap {|c| c['user_ip'] = remote_addr },
            }

            Msgr.publish(exp_api_stmt.as_json, to: 'xikolo.web.exp_event.create')

            entity.attributes.merge('id' => SecureRandom.uuid)
          rescue ArgumentError => e
            raise Xikolo::Error::UnprocessableEntity.new 422, "422 Unprocessable Entity: #{e.message}"
          end
        end
      end
    end
  end
end
