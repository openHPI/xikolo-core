# frozen_string_literal: true

require 'uuid4'

class UserAnswer
  def initialize(data)
    @submission_data = data
  end

  def self.from_submission(_data)
    raise NotImplementedError
  end

  def self.from_snapshot(data, _answers)
    new data
  end

  def self.from_json_api(answer_data, _answers)
    new answer_data['data']
  end

  def to_json_api
    {
      'type' => type,
      'data' => @submission_data,
    }
  end

  def to_submission
    @submission_data
  end

  def type
    raise NotImplementedError
  end
end

class SelectMultipleUserAnswer < UserAnswer
  def self.from_submission(answers)
    new(
      answers.pluck('quiz_answer_id')
    )
  end

  def type
    'select_multiple'
  end
end

class SelectOneUserAnswer < UserAnswer
  def self.from_submission(answers)
    new answers.first['quiz_answer_id']
  end

  def type
    'select_one'
  end
end

class FreeTextUserAnswer < UserAnswer
  def initialize(data, answer_id)
    super(data)

    @answer_id = answer_id
  end

  def self.from_snapshot(data, answers)
    new data.first[1], answers.first['id']
  end

  def self.from_submission(answers)
    new answers.first['user_answer_text'], answers.first['id']
  end

  def self.from_json_api(answer_data, answers)
    new answer_data['data'], answers.first['id']
  end

  def to_submission
    {@answer_id => @submission_data}
  end

  def type
    'free_text'
  end
end

class EssayUserAnswer < UserAnswer
  def self.from_submission(answers)
    new answers.dig(0, 'user_answer_text').to_s
  end

  def type
    'essay'
  end
end

class UserAnswerFactory
  def self.from_submission(question_id, answers)
    make(question_id).from_submission answers
  end

  def self.from_snapshot(question_id, answer_data)
    make(question_id).from_snapshot answer_data, fetch_answers(question_id)
  end

  def self.from_json_api(id, answer_data)
    {
      'select_multiple' => SelectMultipleUserAnswer,
      'select_one' => SelectOneUserAnswer,
      'free_text' => FreeTextUserAnswer,
      'essay' => EssayUserAnswer,
    }.fetch(answer_data['type']).from_json_api answer_data, fetch_answers(id)
  end

  class << self
    private

    def make(question_id)
      question = fetch_question question_id

      {
        'Xikolo::Quiz::MultipleAnswerQuestion' => SelectMultipleUserAnswer,
        'Xikolo::Quiz::MultipleChoiceQuestion' => SelectOneUserAnswer,
        'Xikolo::Quiz::FreeTextQuestion' => FreeTextUserAnswer,
        'Xikolo::Quiz::EssayQuestion' => EssayUserAnswer,
      }.fetch(question['type'])
    end

    def fetch_question(id)
      Xikolo.api(:quiz).value!.rel(:question).get(id:).value!
    end

    def fetch_answers(question_id)
      Xikolo.api(:quiz).value!.rel(:answers).get(question_id:).value!
    end
  end
end

module Xikolo
  module V2::Quiz
    class Submissions < Xikolo::Endpoint::CollectionEndpoint
      load_related_objects = proc {|submission|
        submission['answers'] = {}

        if submission['submitted']
          quiz_api = Xikolo.api(:quiz).value!
          quiz_api.rel(:quiz_submission_questions).get(
            quiz_submission_id: submission['id'],
            per_page: 250
          ).then {|submission_questions|
            Restify::Promise.new(
              submission_questions.map {|question|
                quiz_api.rel(:quiz_submission_answers).get(
                  quiz_submission_question_id: question['id'],
                  per_page: 500
                ).then {|answers|
                  question_id = question['quiz_question_id']
                  submission['answers'][question_id] = UserAnswerFactory.from_submission question_id, answers
                }
              }
            ) { submission }
          }
        elsif submission.rel? :snapshot
          snapshot = submission.rel(:snapshot).get.value!['loaded_data']

          submission['answers'] = snapshot.to_h do |question_id, answer_data|
            [question_id, UserAnswerFactory.from_snapshot(question_id, answer_data)]
          end

          submission
        else
          submission
        end
      }

      entity do
        type 'quiz-submissions'

        attribute('created_at') {
          description 'The date and time when submission data was first saved for this user and quiz'
          type :datetime
          alias_for 'quiz_access_time'
        }

        attribute('submitted_at') {
          description 'The date and time when the user finalized this submission'
          type :datetime
          alias_for 'quiz_submission_time'
        }

        writable attribute('submitted') {
          description 'Whether this submission has been finalized by the user'
          type :boolean
        }

        attribute('points') {
          description 'The total number of points (with decimal) the user received'
          type :float
        }

        writable attribute('answers') {
          description 'A hash of question IDs mapping to an array of submitted answer objects for this question'

          type :hash

          reading {|submission|
            submission['answers'].transform_values(&:to_json_api)
          }

          writing {|value|
            next {} unless value.is_a? Hash

            {
              'submission' => value.to_h {|question_id, submission_data|
                [question_id, UserAnswerFactory.from_json_api(question_id, submission_data).to_submission]
              },
            }
          }
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        has_one('quiz', Xikolo::V2::Quiz::Quizzes) {
          foreign_key 'quiz_id'
        }

        has_one('user', Xikolo::V2::User::Users) {
          foreign_key 'user_id'
        }

        link('self') {|submission| "/api/v2/quiz-submissions/#{submission['id']}" }
      end

      collection do
        post 'Start a quiz submission' do |entity|
          authenticate!

          quiz_id = entity.to_resource['quiz_id']
          course_id = Xikolo.api(:course).value!.rel(:items).get(content_id: quiz_id).value!.first['course_id']

          Xikolo.api(:quiz).value!.rel(:quiz_submissions).post(
            user_id: current_user.id,
            quiz_id:,
            course_id: # WUT????
          ).then {|submission|
            load_related_objects[submission]
          }.value!
        end
      end

      member do
        get 'Load a quiz submission' do
          Xikolo.api(:quiz).value!.rel(:quiz_submission).get(id: UUID(id).to_s).then {|submission|
            authenticate_as! submission['user_id']
            load_related_objects[submission]
          }.value!
        end

        patch 'Update a quiz submission' do |entity|
          submission = Xikolo.api(:quiz).value!.rel(:quiz_submission).get(id: UUID(id).to_s).value!
          authenticate_as! submission['user_id']

          if entity.attributes['submitted']
            submission.rel(:self).patch(
              entity.to_resource,
              id: entity.id
            ).value!
          else
            submission.rel(:snapshots).post(
              submission: entity.to_resource['submission']
            ).value!
          end

          submission.rel(:self).get.then {|resource|
            load_related_objects[resource]
          }.value!
        end
      end
    end
  end
end
