# frozen_string_literal: true

require 'uuid4'

module Xikolo
  module V2::Quiz
    class Quizzes < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'quizzes'

        attribute('instructions') {
          description 'Textual instructions for the quiz taker in Markdown format'
          type :string
        }

        attribute('time_limit') {
          description 'The time (in seconds) that the user can take to finish the quiz, or zero if unlimited'
          type :integer
          reading {|quiz|
            quiz['unlimited_time'] ? 0 : quiz['time_limit_seconds']
          }
        }

        attribute('allowed_attempts') {
          description 'The number of allowed attempts the user has to finish the quiz, or zero if unlimited'
          type :integer
          reading {|quiz|
            quiz['unlimited_attempts'] ? 0 : quiz['allowed_attempts']
          }
        }

        link('self') {|quiz| "/api/v2/quizzes/#{quiz['id']}" }

        includable has_many('questions', V2::Quiz::Questions) {
          filter_by 'quiz'
        }

        includable has_one('newest_user_submission', V2::Quiz::Submissions) {
          foreign_key 'newest_user_submission_id'
        }
      end

      member do
        get 'Retrieve information about a quiz' do
          authenticate!

          quiz_api = Xikolo.api(:quiz).value!

          quiz_api.rel(:quiz).get(id: UUID(id).to_s).then {|quiz|
            quiz_api.rel(:quiz_submissions).get(
              quiz_id: quiz['id'],
              user_id: current_user.id,
              highest_score: false,
              newest_first: true
            ).then {|submissions|
              quiz['newest_user_submission_id'] = submissions.first['id'] if submissions.first
              quiz
            }
          }.value!
        end
      end
    end
  end
end
