# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListSelftests < Xikolo::API
        desc 'Returns all selftests for the user'
        get do
          authenticate!

          courses = course_repo.courses_for current_user, params[:course_id]

          course_api = Xikolo.api(:course).value!
          quiz_api = Xikolo.api(:quiz).value!

          all_questions = courses.map do |course|
            # Fetch all course questions
            questions = get_paged! quiz_api.rel(:questions).get(selftests: true, course_id: course['id']).value!

            Restify::Promise.new(
              questions.map do |question|
                # Fetch the corresponding course items (in parallel!) to enhance the questions with the reference link
                course_api.rel(:items).get(content_id: question['quiz_id']).then do |items|
                  question['course_id'] = course['id']
                  question['reference_link'] = Xikolo::V2::URL.course_item_url(course_id: course['id'], id: items.first['id']) if items.first.present?

                  # The question has been loaded already above. Technically, `Restify::Promise.fulfilled` is not needed.
                  Restify::Promise.fulfilled(question)
                end
              end
            ).value!
          end.flatten

          present :questions, all_questions, with: Xikolo::Entities::Question
          present :answers, all_questions.pluck('answers').flatten, with: Xikolo::Entities::Answer
        end
      end
    end
  end
end
