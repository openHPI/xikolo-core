# frozen_string_literal: true

module Xikolo
  module V2::Features
    class CourseFeatures < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'course-features'

        attribute('features') {
          description 'List of feature flipper\'s name'
          type :array, of: :string
        }
      end

      member do
        get 'Get all course features' do
          authenticate!

          course = Xikolo.api(:course).value!.rel(:course).get(
            id:
          ).value!

          features = Xikolo.api(:account).value!.rel(:user).get(
            id: current_user.id
          ).value!.rel(:features).get(
            context: course['context_id']
          ).value!

          {'id' => course['id'], 'features' => features.keys}
        end
      end
    end
  end
end
