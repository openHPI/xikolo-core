# frozen_string_literal: true

module Xikolo
  module V2::Quiz
    class Questions < Xikolo::Endpoint::CollectionEndpoint
      load_related_objects = proc {|question|
        promise = Xikolo.api(:course).value.rel(:items).get({content_id: question['quiz_id']})

        question['expose_secret_attrs'] = promise.then {|items|
          item = items.first
          !item['submission_deadline'] || (item['submission_publishing_date'] && Time.zone.parse(item['submission_publishing_date']).past?)
        }

        Xikolo.api(:quiz).value
          .rel(:answers).get({question_id: question['id']})
          .then {|answers|
          question['options'] = answers.map {|answer|
            secret_attrs = if question['expose_secret_attrs'].value
                             {
                               'correct' => answer['correct'],
                               'explanation' => answer['comment'],
                             }
                           else
                             {}
                           end

            answer.slice('id', 'text', 'position').merge(secret_attrs)
          }
          question # our return value
        }
      }

      entity do
        type 'quiz-questions'

        attribute('text') {
          description 'The question text'
          type :string
        }

        attribute('explanation') {
          description 'A short text explaining the solution (may be null when this is kept secret)'
          type :string
          reading {|question|
            question['explanation'] if question['expose_secret_attrs'].value
          }
        }

        attribute('type') {
          description 'The question type (one of select_multiple, select_one, or free_text)'
          type :string
          map(
            'Xikolo::Quiz::MultipleAnswerQuestion' => 'select_multiple',
            'Xikolo::Quiz::MultipleChoiceQuestion' => 'select_one',
            'Xikolo::Quiz::FreeTextQuestion' => 'free_text',
            'Xikolo::Quiz::EssayQuestion' => 'essay'
          )
        }

        attribute('position') {
          description 'The question\'s position within its quiz'
          type :integer
        }

        attribute('max_points') {
          description 'The maximum number of points (with decimal) that can be achieved with this question'
          type :float
          alias_for 'points'
        }

        attribute('shuffle_options') {
          description 'Whether the options should be shown in random order'
          type :boolean
          alias_for 'shuffle_answers'
        }

        attribute('eligible_for_recap') {
          description 'Whether the question is eligible for a quiz recap'
          type :boolean
        }

        attribute('options') {
          description 'An array of possible options'
          type :array, of: nested_type(:hash, of: {
            id: :string,
            position: :integer,
            text: :string,
            correct: :boolean,
            explanation: :string,
          })
        }

        link('self') {|question| "/api/v2/quiz-questions/#{question['id']}" }

        has_one('quiz', Xikolo::V2::Quiz::Quizzes) {
          foreign_key 'quiz_id'
        }
      end

      filters do
        required('quiz') {
          description 'Only return questions belonging to the quiz with this UUID'
          alias_for 'quiz_id'
        }
      end

      collection do
        get 'Retrieve all questions for a given quiz' do
          authenticate!

          Xikolo.api(:quiz).value.rel(:questions).get(filters).then {|questions|
            Restify::Promise.new(questions.map {|question|
              load_related_objects[question]
            })
          }.value!
        end
      end

      member do
        get 'Retrieve a quiz question by ID' do
          authenticate!

          Xikolo.api(:quiz).value.rel(:question).get({id:}).then {|question|
            load_related_objects[question]
          }.value!
        end
      end
    end
  end
end
