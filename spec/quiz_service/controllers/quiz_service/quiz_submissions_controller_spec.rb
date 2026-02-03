# frozen_string_literal: true

require 'spec_helper'

describe QuizService::QuizSubmissionsController, type: :controller do
  include_context 'quiz_service API controller'

  let(:quiz) { create(:'quiz_service/quiz', id: '00000000-0000-4444-9999-999999999991') }
  let(:quiz_submission) { create(:'quiz_service/quiz_submission', :submitted, quiz:) }
  let(:wrong_quiz_submission_id) { '00000000-0000-4444-9999-999999999991' }
  let(:unsubmitted_quiz_submission) { create(:'quiz_service/quiz_submission', quiz:) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject { -> { action } }

    let(:params) { {} }
    let(:action) { get :index, params: }

    shared_examples_for 'a successful index call' do
      describe 'call' do
        subject { super().call }

        it { is_expected.to be_successful }
      end

      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to be_a Array }
      end
    end

    context 'should answer with a list' do
      before { quiz_submission }

      it_behaves_like 'a successful index call'
      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to have(1).item }
      end
    end

    context 'should answer with quiz_submission objects' do
      before { quiz_submission }

      it_behaves_like 'a successful index call'
      describe 'response' do
        subject { json }

        before { action }

        it { is_expected.to be_a Array }

        its(:first) { is_expected.to eq QuizService::QuizSubmissionDecorator.new(quiz_submission).as_json(api_version: 1) }
      end
    end

    context 'with submitted param' do
      let(:params) { super().merge(submitted: submitted_param) }

      before { quiz_submission; unsubmitted_quiz_submission; action }

      context 'submitted=true' do
        let(:submitted_param) { 'true' }

        it 'returns only the submitted quiz submission' do
          expect(json.pluck('id')).to contain_exactly(quiz_submission.id)
        end
      end

      context 'submitted=false' do
        let(:submitted_param) { 'false' }

        it 'returns only the unsubmitted quiz submission' do
          expect(json.pluck('id')).to contain_exactly(unsubmitted_quiz_submission.id)
        end
      end
    end

    context 'with highest_score param' do
      let!(:quiz_submission1) { create(:'quiz_service/quiz_submission', quiz:, created_at: 5.days.ago, quiz_submission_time: 4.days.ago) }
      let!(:quiz_submission2) { create(:'quiz_service/quiz_submission', quiz:, created_at: 3.days.ago, quiz_submission_time: 2.days.ago) }
      let!(:quiz_submission3) { create(:'quiz_service/quiz_submission', quiz:, created_at: 2.days.ago, quiz_submission_time: 1.day.ago) }

      before do
        create_list(:'quiz_service/quiz_submission_question', 3, points: 3.0, quiz_submission: quiz_submission1)
        create_list(:'quiz_service/quiz_submission_question', 3, points: 5.0, quiz_submission: quiz_submission2)
        create_list(:'quiz_service/quiz_submission_question', 3, points: 2.0, quiz_submission: quiz_submission3)
      end

      context 'with highest_score true' do
        let(:params) { super().merge(highest_score: 'true') }

        before { action }

        it 'sorts submissions by points in descending order' do
          expect(json.first).to eq QuizService::QuizSubmissionDecorator.new(quiz_submission2).as_json(api_version: 1)
        end
      end

      context 'with highest_score false' do
        let(:params) { super().merge(highest_score: 'false') }

        before { action }

        it 'sorts submissions by creation date, newest last' do
          expect(json.last).to eq QuizService::QuizSubmissionDecorator.new(quiz_submission3).as_json(api_version: 1)
        end
      end

      context 'with newest_first' do
        let(:params) { super().merge(highest_score: 'false', newest_first: 'true') }

        before { action }

        it 'sorts submissions by submission date, newest first' do
          expect(json.first).to eq QuizService::QuizSubmissionDecorator.new(quiz_submission3).as_json(api_version: 1)
        end
      end
    end
  end

  describe '#show' do
    it 'responds with 200 Ok' do
      get :show, params: {id: quiz_submission.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with quiz_submission object' do
      get :show, params: {id: quiz_submission.id}
      expect(json).to eq(QuizService::QuizSubmissionDecorator.new(quiz_submission).as_json(api_version: 1).stringify_keys)
    end

    it 'does not include a snapshot URL in its answer' do
      get :show, params: {id: quiz_submission.id}
      expect(json).not_to include 'snapshot_url'
    end

    context 'when there is a snapshot for the submission' do
      before { create(:'quiz_service/quiz_submission_snapshot', quiz_submission_id: quiz_submission.id) }

      it 'includes the snapshot\'s URL in its answer' do
        get :show, params: {id: quiz_submission.id}
        expect(json).to include 'snapshot_url'
      end
    end

    it 'responds with 404 Not Found for a wrong ID' do
      get :show, params: {id: wrong_quiz_submission_id}
      expect(response).to have_http_status :not_found
    end
  end

  describe '#update' do
    subject(:modification) { action_proc }

    before do
      create(:'quiz_service/multiple_answer_question',
        id: '00000000-0000-4444-9999-000000000001',
        quiz:,
        points: 10,
        shuffle_answers: false,
        position: 1)

      create(:'quiz_service/multiple_choice_question',
        id: '00000000-0000-4444-9999-000000000002',
        quiz:,
        points: 10,
        shuffle_answers: false,
        position: 2)

      create(:'quiz_service/multiple_choice_question',
        id: '00000000-0000-4444-9999-000000000005',
        quiz:,
        points: 10,
        shuffle_answers: true,
        position: 3)

      create(:'quiz_service/free_text_question',
        id: '00000000-0000-4444-9999-000000000006',
        quiz:,
        points: 5,
        shuffle_answers: true,
        position: 4)

      create(:'quiz_service/essay_question',
        id: '00000000-0000-4444-9999-000000000007',
        quiz:,
        points: 10,
        shuffle_answers: true,
        position: 5)

      create(:'quiz_service/free_text_question',
        id: '00000000-0000-4444-9999-000000000008',
        quiz:,
        points: 5,
        shuffle_answers: true,
        case_sensitive: true,
        position: 6)

      create(:'quiz_service/free_text_question',
        id: '00000000-0000-4444-9999-000000000009',
        quiz:,
        points: 5,
        shuffle_answers: true,
        case_sensitive: false,
        position: 6)

      create(:'quiz_service/text_answer',
        id: '00000000-0000-4444-9999-000000000001',
        question_id: '00000000-0000-4444-9999-000000000001',
        comment: 'Kekse sind lecker.',
        correct: true)

      create(:'quiz_service/text_answer',
        id: '00000000-0000-4444-9999-000000000002',
        question_id: '00000000-0000-4444-9999-000000000001',
        comment: 'Kekse sind doof.',
        correct: false)

      create(:'quiz_service/text_answer',
        id: '00000000-0000-4444-9999-000000000003',
        question_id: '00000000-0000-4444-9999-000000000002',
        comment: 'Kuchen ist toll.',
        correct: false)

      create(:'quiz_service/text_answer',
        id: '00000000-0000-4444-9999-000000000005',
        question_id: '00000000-0000-4444-9999-000000000005',
        comment: 'Obst ist auch essbar.',
        correct: true)

      create(:'quiz_service/text_answer',
        id: '00000000-0000-4444-9999-000000000007',
        question_id: '00000000-0000-4444-9999-000000000005',
        comment: 'Obst ist doof.',
        correct: false)

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000008',
        question_id: '00000000-0000-4444-9999-000000000006',
        correct: true,
        text: '400')

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000009',
        question_id: '00000000-0000-4444-9999-000000000006',
        correct: true,
        text: '401')

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000010',
        question_id: '00000000-0000-4444-9999-000000000007',
        correct: true,
        text: '404 long text Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.
                At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.')

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000011',
        question_id: '00000000-0000-4444-9999-000000000006',
        correct: false,
        text: 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
           Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec.')

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000012',
        question_id: '00000000-0000-4444-9999-000000000008',
        correct: true,
        text: 'CaseSensitive')

      create(:'quiz_service/free_text_answer',
        id: '00000000-0000-4444-9999-000000000013',
        question_id: '00000000-0000-4444-9999-000000000009',
        correct: true,
        text: 'CaseSensitive')

      Stub.request(
        :course, :get, '/items',
        query: {content_id: quiz_submission.quiz_id}
      ).to_return Stub.json([
        {id: '00000000-3300-4444-9999-000000000001'},
      ])
    end

    let(:params) { quiz_submission_attributes }
    let(:quiz_submission_attributes) { attributes_for(:'quiz_service/quiz_submission', :submitted, quiz_id: quiz.id) }
    let(:unsubmitted_quiz_submission_attributes) { attributes_for(:'quiz_service/quiz_submission', quiz_id: quiz.id) }

    let(:submission_points) { 20.0 }
    let!(:item_result_1) do
      Stub.request(
        :course, :put, "/results/#{quiz_submission.id}",
        body: hash_including(
          item_id: '00000000-3300-4444-9999-000000000001',
          user_id: quiz_submission.user_id,
          points: submission_points
        )
      ).to_return Stub.json(nil)
    end
    let!(:item_result_2) do
      Stub.request(
        :course, :put, "/results/#{unsubmitted_quiz_submission.id}",
        body: hash_including(
          item_id: '00000000-3300-4444-9999-000000000001',
          user_id: unsubmitted_quiz_submission.user_id,
          points: submission_points
        )
      ).to_return Stub.json(nil)
    end

    let(:action_proc) { -> { put :update, params: {id: quiz_submission.id}, body: params.merge(user_id: '00000000-0000-4444-9999-000000000002').to_json, as: :json } }
    let(:action) { action_proc.call }

    its(:call) { is_expected.to be_successful }
    its('call.status') { is_expected.to eq 204 }

    it 'responds with 204 No Content' do
      put :update, params: {id: quiz_submission.id}, body: params.merge(user_id: '00000000-0000-4444-9999-000000000002').to_json, as: :json
      expect(response).to have_http_status :no_content
    end

    context 'with submitted param' do
      let(:timestamp) { DateTime.parse('2017-08-10 11:00:00') }
      let(:action_proc) { -> { put :update, params: {id: unsubmitted_quiz_submission.id}, body: params.merge(user_id: '00000000-0000-4444-9999-000000000002').to_json, as: :json } }
      let(:params) { {submitted: true} }
      let(:submission_points) { 0.0 }
      let(:submission) { QuizService::QuizSubmission.find unsubmitted_quiz_submission.id }

      before { Timecop.freeze timestamp }

      after { Timecop.return }

      context 'with time limit passed' do
        # Time for quiz is up
        let(:timestamp) { (unsubmitted_quiz_submission.created_at + (quiz.time_limit_seconds + 60).seconds).change(usec: 0) }

        it 'marks the submission as submitted' do
          action
          expect(submission.submitted).to be_truthy
        end

        it 'stores the corresponding quiz version with the submission' do
          action
          expect(submission.quiz_version_at).to eql submission.quiz_access_time
        end

        it 'sets the quiz submission time to the current time' do
          action
          expect(submission.quiz_submission_time.to_s).to eq timestamp.to_s
        end

        it '(asynchronously) creates an item result resource' do
          Sidekiq::Testing.inline! { action }

          expect(item_result_2).to have_been_requested
        end

        context 'with unlimited time' do
          let(:quiz) { create(:'quiz_service/quiz', :unlimited_time) }

          it 'stores the submission time' do
            action
            expect(submission.quiz_submission_time).to eq timestamp
          end
        end
      end

      context 'without time limit passed' do
        it 'marks the submission as submitted' do
          action

          expect(submission.submitted).to be_truthy
          expect(submission.quiz_submission_time).to eq timestamp
        end

        it 'stores the corresponding quiz version with the submission' do
          action
          expect(submission.quiz_version_at).to eql submission.quiz_access_time
        end

        it '(asynchronously) creates an item result resource' do
          Sidekiq::Testing.inline! { action }

          expect(item_result_2).to have_been_requested
        end
      end

      # This can happen when using Acfs (which always transfers all attributes, not just ones that changed)
      context 'and fudge points' do
        let(:params) { super().merge(fudge_points: 0.0) }

        it '(asynchronously) creates an item result resource only once' do
          Sidekiq::Testing.inline! { action }

          expect(item_result_2).to have_been_requested.once
        end
      end
    end

    context 'without submitted param' do
      let(:quiz_submission) { create(:'quiz_service/quiz_submission', quiz:) }
      let(:params) { {submitted: false} }

      it 'does not mark the submission as submitted' do
        action
        quiz_submission.reload

        expect(quiz_submission.quiz_submission_time).to be_nil
        expect(quiz_submission.submitted).to be_falsey
      end

      it '(asynchronously) does not create an item result resource' do
        Sidekiq::Testing.inline! { action }

        expect(item_result_2).not_to have_been_requested
      end
    end

    context 'with submission hash' do
      let(:quiz_submission) { create(:'quiz_service/quiz_submission', quiz:) }
      let(:params) do
        super().merge submission: {
                        '00000000-0000-4444-9999-000000000001' =>
                            ['00000000-0000-4444-9999-000000000001'],
         '00000000-0000-4444-9999-000000000002' =>
             '00000000-0000-4444-9999-000000000003',
         '00000000-0000-4444-9999-000000000005' =>
             '00000000-0000-4444-9999-000000000005',
                      },
          submitted: true
      end

      it 'creates three new question objects for the submission' do
        expect { modification.call }.to change { quiz_submission.quiz_submission_questions.count }.by 3
      end

      it 'creates three new answer objects to go along with those questions' do
        expect { modification.call }.to change {
          quiz_submission.reload.quiz_submission_questions.flat_map(&:quiz_submission_answers).count
        }.by 3
      end

      it 'responds with 200 Ok' do
        expect(response).to have_http_status(:ok)
      end

      it '(asynchronously) updates questions statistics' do
        Sidekiq::Testing.inline! do
          expect { action }.to change(QuizService::QuestionStatistics, :count).from(0).to(7)
        end
      end

      context 'awarding points' do
        context 'with all correct answers' do
          it 'awards 20 points' do
            action
            expect(QuizService::QuizSubmission.first.points).to eq 20
          end

          it 'awards the first SubmissionQuestion with 10 points' do
            action
            expect(QuizService::QuizSubmission.first.quiz_submission_questions.first.points).to eq 10
          end
        end

        context 'with wrong answers' do
          let(:action_proc) { -> { put :update, params: {id: unsubmitted_quiz_submission.id}, body: params.merge(user_id: '00000000-0000-4444-9999-000000000002').to_json, as: :json } }
          let(:params) do
            unsubmitted_quiz_submission_attributes.merge submission: {
                                                           '00000000-0000-4444-9999-000000000001' =>
                                                               ['00000000-0000-4444-9999-000000000001'],
             '00000000-0000-4444-9999-000000000002' =>
                 '00000000-0000-4444-9999-000000000003',
             '00000000-0000-4444-9999-000000000005' =>
                 '00000000-0000-4444-9999-000000000007',
                                                         },
              submitted: true
          end
          let(:submission_points) { 10.0 }

          it 'awards only 10 points' do
            action
            submission = QuizService::QuizSubmission.find unsubmitted_quiz_submission.id
            expect(submission.points).to eq 10
          end

          it '(asynchronously) creates an item result resource' do
            Sidekiq::Testing.inline! { action }

            expect(item_result_2).to have_been_requested
          end
        end

        context 'with both wrong and right answer selected' do
          let(:params) do
            quiz_submission_attributes.merge submission: {
              '00000000-0000-4444-9999-000000000001' =>
                %w[00000000-0000-4444-9999-000000000001 00000000-0000-4444-9999-000000000002],
            }
          end

          it 'awards 0 points' do
            expect(QuizService::QuizSubmission.first.points).to eq 0
          end
        end
      end

      context 'with FreeTextQuestion' do
        let(:params) do
          super().merge submission: {
                          '00000000-0000-4444-9999-000000000001' =>
                              ['00000000-0000-4444-9999-000000000001'],
         '00000000-0000-4444-9999-000000000002' =>
             '00000000-0000-4444-9999-000000000003',
         '00000000-0000-4444-9999-000000000005' =>
             '00000000-0000-4444-9999-000000000005',
         '00000000-0000-4444-9999-000000000006' =>
             {'00000000-0000-4444-9999-000000000008' => '400'},
                        },
            submitted: true
        end

        let(:submission_points) { 25.0 }

        it 'changes the question count' do
          expect { action }.to change(QuizService::QuizSubmissionQuestion, :count).by(4)
            .and change(QuizService::QuizSubmissionAnswer, :count).by(4)
        end

        it 'responds with 200 Ok' do
          expect(response).to have_http_status(:ok)
        end

        context 'with answers longer than 255 characters' do
          let(:params) do
            super().merge submission: {
                            '00000000-0000-4444-9999-000000000006' =>
                                {'00000000-0000-4444-9999-000000000011' => 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
                    Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec.'},
                          },
              submitted: true
          end

          it 'does not change the question quantity' do
            expect { response }.not_to change(QuizService::QuizSubmissionQuestion, :count)
          end

          it 'also does not change the answer quantity' do
            expect { response }.not_to change(QuizService::QuizSubmissionAnswer, :count)
          end
        end

        context 'awarding points' do
          before { action }

          context 'with correct answers' do
            it 'awards 25 points' do
              expect(QuizService::QuizSubmission.first.points).to eq 25
            end

            it 'awards the FreeTextQuestion with 5 points' do
              expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 5
            end

            context 'with a second possible answer' do
              let(:params) do
                super().merge submission: {
                                '00000000-0000-4444-9999-000000000001' =>
                                    ['00000000-0000-4444-9999-000000000001'],
               '00000000-0000-4444-9999-000000000002' =>
                   '00000000-0000-4444-9999-000000000003',
               '00000000-0000-4444-9999-000000000005' =>
                   '00000000-0000-4444-9999-000000000005',
               '00000000-0000-4444-9999-000000000006' =>
                   {'00000000-0000-4444-9999-000000000008' => '401'},
                              },
                  submitted: true
              end

              it 'stills award the FreeTextQuestion with 5 points' do
                expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 5
              end
            end

            context 'with case sensitive flag set and correct answer' do
              let(:params) do
                super().merge submission: {
                  '00000000-0000-4444-9999-000000000008' =>
                      {'00000000-0000-4444-9999-000000000012' => 'CaseSensitive'},
                }
              end
              let(:submission_points) { 5.0 }

              it 'awards the FreeTextQuestion with 5 points' do
                expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 5
              end
            end

            context 'with the case sensitive flag not set and correct answer' do
              let(:params) do
                super().merge submission: {
                  '00000000-0000-4444-9999-000000000009' =>
                      {'00000000-0000-4444-9999-000000000013' => 'CaseSensitive'},
                }
              end
              let(:submission_points) { 5.0 }

              it 'awards the FreeTextQuestion with 5 points' do
                expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 5
              end
            end
          end

          context 'with wrong free_text_answer' do
            let(:params) do
              quiz_submission_attributes.merge submission: {
                                                 '00000000-0000-4444-9999-000000000001' =>
                                                 ['00000000-0000-4444-9999-000000000001'],
             '00000000-0000-4444-9999-000000000002' =>
                 '00000000-0000-4444-9999-000000000003',
             '00000000-0000-4444-9999-000000000005' =>
                 '00000000-0000-4444-9999-000000000005',
             '00000000-0000-4444-9999-000000000006' =>
             {'00000000-0000-4444-9999-000000000008' => '404'},
                                               },
                submitted: true
            end
            let(:submission_points) { 20.0 }

            it 'awards only 20 points' do
              expect(QuizService::QuizSubmission.first.points).to eq 20
            end

            it 'awards the FreeTextQuestion with 0 points' do
              expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 0
            end
          end

          context 'with upper-case answer and case sensitive flag set' do
            let(:params) do
              super().merge submission: {
                '00000000-0000-4444-9999-000000000008' =>
                    {'00000000-0000-4444-9999-000000000012' => 'CASESENSITIVE'},
              }
            end
            let(:submission_points) { 0.0 }

            it 'awards the FreeTextQuestion with 0 points' do
              expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 0
            end
          end

          context 'with upper-case answer and case sensitive flag not set' do
            let(:params) do
              super().merge submission: {
                '00000000-0000-4444-9999-000000000009' =>
                    {'00000000-0000-4444-9999-000000000012' => 'CASESENSITIVE'},
              }
            end
            let(:submission_points) { 5.0 }

            it 'awards the FreeTextQuestion with 5 points' do
              expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 5
            end
          end
        end
      end

      context 'with EssayQuestions' do
        let(:text) do
          <<~TEXT
            404 long text Lorem ipsum dolor sit amet, consetetur sadipscing
            elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore
            magna aliquyam erat, sed diam voluptua. At vero eos et accusam et
            justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea
            takimata sanctus est Lorem ipsum dolor sit amet.
          TEXT
        end

        let(:params) do
          quiz_submission_attributes.merge submission: {
                                             '00000000-0000-4444-9999-000000000001' =>
                                                 ['00000000-0000-4444-9999-000000000001'],
           '00000000-0000-4444-9999-000000000002' =>
               '00000000-0000-4444-9999-000000000003',
           '00000000-0000-4444-9999-000000000005' =>
               '00000000-0000-4444-9999-000000000005',
           '00000000-0000-4444-9999-000000000007' => text,
                                           },
            submitted: true
        end
        let(:submission_points) { 30.0 }

        it 'responds with 200 Ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'changes the question count' do
          expect { action }.to change(QuizService::QuizSubmissionQuestion, :count).by(4)
            .and change(QuizService::QuizSubmissionAnswer, :count).by(4)
        end

        context 'the stored answer' do
          subject(:stored_answer) { modification.call; QuizService::QuizSubmissionFreeTextAnswer.last }

          it 'returns user answer text' do
            expect(stored_answer.user_answer_text).to eq text
          end

          its(:quiz_answer_id) { is_expected.to be_nil }
        end

        context 'awarding points' do
          before { action }

          it 'awards 30 points' do
            expect(QuizService::QuizSubmission.first.points).to eq 30
          end

          it 'awards the essay question with 10 points' do
            expect(QuizService::QuizSubmission.first.quiz_submission_questions.last.points).to eq 10
          end
        end
      end

      describe 'resend same submission' do
        subject { action_proc }

        before { action }

        it 'responds with 201 No Content' do
          expect(response).to have_http_status(:no_content)
        end

        it 'does not change the count' do
          expect { action_proc }.not_to change(QuizService::QuizSubmissionQuestion, :count)
          expect { action_proc }.not_to change(QuizService::QuizSubmissionAnswer, :count)
        end
      end
    end

    context 'with fudge_points param' do
      before do
        create(:'quiz_service/quiz_submission_question',
          quiz_submission_id: quiz_submission.id,
          points: 3.0)
      end

      let(:params) { {fudge_points: 2.0} }
      let(:submission_points) { 5.0 } # needed for item stub

      it 'changes the total points' do
        expect { action }.to change { quiz_submission.reload.points }.from(3).to(5)
      end

      it 'stores the new fudge points' do
        expect { action }.to change { quiz_submission.reload.fudge_points }.from(0).to(2)
      end

      it '(asynchronously) updates the item result' do
        Sidekiq::Testing.inline! { action }

        expect(item_result_1).to have_been_requested
      end
    end

    context 'with available vendor data param' do
      describe 'proctoring data available' do
        let(:vendor_data) { {'proctoring_smowl' => {'wrongimage' => '0'}} }
        let(:params) { {vendor_data:} }

        it 'stores the new vendor data' do
          expect { action }.to change { quiz_submission.reload.vendor_data }.from({}).to(vendor_data)
        end
      end

      describe 'with existing proctoring data' do
        let(:vendor_data) { {'proctoring_smowl' => {'wrongimage' => '0'}} }
        let(:quiz_submission1) do
          create(:'quiz_service/quiz_submission',
            :submitted,
            quiz:,
            created_at: 5.days.ago,
            vendor_data:)
        end
        let(:params) { {vendor_data: {}} }

        it 'does not overwrite vendor data with empty values' do
          expect { action }.not_to change { quiz_submission1.reload.vendor_data }
        end
      end
    end
  end

  describe '#destroy' do
    subject(:deletion) { delete :destroy, params: {id: quiz_submission.id} }

    it 'responds with 204 No Content' do
      deletion
      expect(response).to have_http_status :no_content
    end

    it 'removes a quiz submission' do
      quiz_submission
      expect { deletion }.to change(QuizService::QuizSubmission, :count).from(1).to(0)
    end
  end
end
