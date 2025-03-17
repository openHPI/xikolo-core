# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class RepetitionSuggestions < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'repetition-suggestions'

        attribute('title') {
          description 'The repetition suggestion\'s title'
          type :string
        }

        attribute('content_type') {
          description 'The type of item: one of quiz, video, rich_text, lti_exercise'
          type :string
        }

        attribute('icon') {
          description 'The icon for this item (reflecting the icon in the xikolo-font)'
          type :string
          reading {|item| ItemPresenter.new(item:).icon_class }
        }

        attribute('exercise_type') {
          description 'The rank of this exercise: one of main, bonus, selftest, survey'
          type :string
        }

        attribute('user_points') {
          description 'The (maximum) number of points (with decimal) that the user scored for this item'
          type :float
        }

        attribute('max_points') {
          description 'The number of points (with decimal) that can be achieved with this item'
          type :float
        }

        attribute('percentage') {
          description 'The percentage of scored points (with regard to the max_points) for this item'
          type :integer
          alias_for 'points_percentage'
        }

        link('item_html') {|res| Xikolo::V2::URL.course_item_path res['course_id'], UUID(res['id']).to_param }
        link('pinboard_html') {|res| Xikolo::V2::URL.course_section_pinboard_index_path res['course_id'], UUID(res['section_id']).to_param }
      end

      filters do
        required('course') {
          description 'Only return repetition suggestions belonging to the course with this UUID'
          alias_for 'course_id'
        }
      end

      collection do
        get 'List all repetition suggestions for the current user' do
          suggestions = []
          if current_user.logged_in?
            suggestions = Xikolo.api(:course).value!.rel(:repetition_suggestions).get(
              filters.merge(
                user_id: current_user.id,
                exercise_type: 'selftest',
                limit: 3
              )
            ).value!
          end
          suggestions
        end
      end
    end
  end
end
