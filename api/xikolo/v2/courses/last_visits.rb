# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class LastVisits < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'last-visits'

        id {|last_visit| last_visit['resource_id'] }

        attribute('visit_date') {
          description 'The date of the last item visit'
          type :datetime
        }

        has_one('item', Xikolo::V2::Courses::Items) {
          foreign_key 'item_id'
        }
      end

      member do
        get 'Get last visit information' do
          authenticate!

          Xikolo.api(:course).value!.rel(:last_visit).get({
            course_id: id,
            user_id: current_user.id,
          }).value!.merge(resource_id: id)
        end
      end
    end
  end
end
