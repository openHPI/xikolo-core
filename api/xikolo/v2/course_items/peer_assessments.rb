# frozen_string_literal: true

module Xikolo
  module V2::CourseItems
    class PeerAssessments < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'peer-assessments'

        attribute('instructions') {
          type :string
        }

        attribute('type') {
          type :string
          description 'Either solo or team'
          reading {|pa|
            pa['is_team_assessment'] ? 'team' : 'solo'
          }
        }
      end

      member do
        get 'Retrieve information about a peer assessment task' do
          authenticate!

          item = ::Course::Item.find_by(content_id: id)
          course = item&.section&.course
          not_found! unless item&.available? && course.present?

          in_context course.context_id

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          Xikolo.api(:peerassessment).value!.rel(:peer_assessment).get(id:).value!
        end
      end
    end
  end
end
