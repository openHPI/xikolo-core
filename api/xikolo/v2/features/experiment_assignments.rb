# frozen_string_literal: true

module Xikolo
  module V2::Features
    class ExperimentAssignments < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'experiment-assignments'

        # Experiment assignments are not directly stored in the database and
        # are not meant to be stored by the API consumer. This was only added
        # to ensure conformance to the JSON:API specification.
        id { SecureRandom.uuid }

        writable attribute('identifier') {
          description 'The identifier of the experiment. Required for POST.'
          type :string
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }
      end

      collection do
        post 'Create experiment assignment' do |entity|
          # This will always return a successful response regardless of
          # previous assignments to experiments, invalid experiment identifiers,
          # invalid course ids, and passed course ids for global experiments.
          # This mirrors the behavior of the `assign` method.
          authenticate!

          res = entity.to_resource

          raise Xikolo::Error::InvalidValue if res['identifier'].blank?

          experiment = Experiment.new(res['identifier'], course_id: res['course_id'])
          experiment.assign!(current_user)

          res
        end
      end
    end
  end
end
