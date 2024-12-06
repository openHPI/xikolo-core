# frozen_string_literal: true

require 'spec_helper'

describe ReviewsController, type: :controller do
  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment)  { create(:peer_assessment, :with_steps, :with_rubrics) }

  let(:shared_submission) { create(:shared_submission, peer_assessment_id: peer_assessment.id) }
  let(:submission) { create(:submission, :with_pool_entries, shared_submission:) }

  describe '#index' do
    subject(:index) { get :index, params: }

    before do
      5.times do
        shared_s = create(:shared_submission, :as_submitted, peer_assessment_id: peer_assessment.id)
        s = create(:submission, :with_pool_entries,
          shared_submission: shared_s,
          user_id: SecureRandom.uuid)

        create(:review, :as_submitted,
          step: peer_assessment.grading_step,
          user_id: SecureRandom.uuid,
          submission_id: s.id)
      end
    end

    it 'is successful' do
      index
      expect(response).to be_successful
    end

    it 'retrieves all reviews' do
      index
      expect(json.size).to eq(Review.all.size)
    end

    describe 'for one specific peer assessment' do
      let(:additional_params) { {peer_assessment_id: peer_assessment.id} }

      it 'retrieves the correct amount of reviews' do
        index
        expect(json.size).to eq 5
      end

      context 'submission requested as training sample' do
        let(:user_id) { SecureRandom.uuid }
        let(:additional_params) { {peer_assessment_id: peer_assessment.id, as_train_sample: true, user_id:} }

        before do
          Stub.service(
            :account,
            user_url: '/users/{id}'
          )

          Stub.request(
            :account, :get, "/users/#{user_id}"
          ).to_return Stub.json({
            id: user_id,
            avatar_url: 'https://s3.xikolo.de/xikolo-public/avatar/003.jpg',
            email: 'test@example.de',
            permissions_url: "/permissions?user_id=#{user_id}",
          })

          Stub.request(
            :account, :get, "/permissions?user_id=#{user_id}"
          ).to_return Stub.json([])
        end

        context 'with no available samples' do
          before do
            PoolEntry.delete_all
          end

          it 'is successful' do
            index
            expect(response).to be_successful
          end

          it 'returns a nil (empty) response' do
            index
            expect(json.first).to be_nil
          end
        end

        context 'with a submission which is not allowed as sample' do
          before do
            PoolEntry.delete_all

            shared_submission.update disallowed_sample: true

            # Create necessary pool entries
            submission.handle_training_pool_entry
          end

          it 'is successful' do
            index
            expect(response).to be_successful
          end

          it 'returns a nil (empty) response' do # Submission will be ignored
            index
            expect(json.first).to be_nil
          end
        end

        context 'with an available submission' do
          before do
            PoolEntry.delete_all

            # Create necessary pool entries
            submission.handle_training_pool_entry
          end

          it 'is successful' do
            index
            expect(response).to be_successful
          end

          it 'retrieves a training sample' do
            expect do
              index
            end.to change { Review.all.size }.by(1)

            expect(json.first['submission_id']).to eq(submission.id) # Only submission int the pool
          end
        end
      end
    end

    context 'with team submissions' do
      let(:submission) { Submission.first }
      let(:user_id) { submission.user_id }
      let(:additional_params) do
        {
          submission_id: submission.id,
          submitted: true,
          step_id: peer_assessment.grading_step.id,
        }
      end
      let!(:r1) { submission.reviews.first }
      let!(:r2) { Review.where.not(id: r1.id).first }

      before do
        submission.update! shared_submission_id: r2.submission.shared_submission_id
      end

      it 'returns one review' do
        index
        expect(json).to have(1).item
      end

      context 'with with_team_submissions set to true' do
        let(:additional_params) { super().merge(with_team_submissions: true) }

        it 'returns reviews of team submissions' do
          index
          expect(json.pluck('id')).to contain_exactly(r1.id, r2.id)
        end
      end
    end
  end

  describe '#show' do
    subject(:show) { get :show, params: }

    before { shared_submission.update submitted: true }

    let!(:review) do
      create(:review, :as_submitted,
        user_id: SecureRandom.uuid,
        submission_id: submission.id,
        step: peer_assessment.steps[2],
        text:)
    end
    let(:text) { 'Lorem Ipsum' }

    describe 'with a valid id' do
      let(:additional_params) { {id: review.id} }

      it 'is successful' do
        show
        expect(response).to be_successful
      end

      it 'does not retrieve an array' do
        show
        expect(json.is_a?(Array)).to be(false)
      end

      it 'contains the requested id' do
        show
        expect(json['id']).to eq(review.id)
      end
    end

    describe '#text' do
      let(:additional_params) { {id: review.id} }
      let(:text) { 'some text\ns3://xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg' }

      it 'returns text with public URLs' do
        show
        expect(json['text']).to eq 'some text\nhttps://s3.xikolo.de/xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg'
      end

      context 'in raw mode' do
        let(:additional_params) { {id: review.id, raw: true} }

        it 'returns the markup enhanced with url mappings and other files references' do
          show
          expect(json['text']).to eq(
            'markup' =>
              'some text\ns3://xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg',
            'url_mapping' => {
              's3://xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg' =>
                 'https://s3.xikolo.de/xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg',
            },
            'other_files' => {
              's3://xikolo-peerassessment/assessments/34/rtfiles/34/hans.jpg' => 'hans.jpg',
            }
          )
        end
      end
    end

    describe 'with an invalid id' do
      let(:invalid_id) { SecureRandom.uuid }
      let(:additional_params) { {id: invalid_id} }

      it 'returns nil' do
        show
        expect(json).to be_empty
      end

      it 'is not successful' do
        show
        expect(response).not_to be_successful
      end
    end
  end

  describe '#update' do
    subject(:modification) { post :update, params: }

    before { shared_submission.update submitted: true }

    let!(:review) do
      create(:review,
        user_id: SecureRandom.uuid,
        submission_id: submission.id,
        step_id: peer_assessment.grading_step.id)
    end

    let!(:training_review) do
      create(:review, :as_train_review,
        user_id: SecureRandom.uuid,
        submission_id: submission.id,
        step_id: peer_assessment.training_step.id)
    end

    describe 'extending a deadline' do
      let(:additional_params) { {id: review.id, extended: true, text: 'New Text!'} }

      it 'extends the deadline' do
        expect do
          modification
        end.to change { review.reload.deadline }.by 2.hours
      end

      it 'does not update anything else' do
        modification
        expect(review.reload.text).not_to eq(additional_params['text'])
      end

      it 'does not work on already extended review deadlines' do
        review.extended = true
        review.save!

        expect do
          modification
        end.not_to change { review.reload.deadline }
      end
    end

    describe 'updating a training review' do
      let(:additional_params) do
        {id: training_review.id,
                                  text: 'New Text',
                                  award: true,
                                  submission_id: SecureRandom.uuid,
                                  deadline: 1.week.from_now,
                                  train_review: false,
                                  step_id: SecureRandom.uuid,
                                  user_id: SecureRandom.uuid,
                                  optionIDs: get_valid_rubrics(peer_assessment),
                                  submitted: true}
      end

      it 'is successful' do
        modification
        expect(response).to be_successful
      end

      it 'only updates allowed attributes' do
        submission_id = submission.id
        user_id = training_review.user_id
        step_id = training_review.step_id

        modification

        expect(training_review.reload.text).to eq('New Text')
        expect(training_review.award).to be(true)
        expect(training_review.submitted).to be(true)
        expect(training_review.train_review).to be(true)
        expect(training_review.submission_id).to eq(submission_id)
        expect(training_review.user_id).to eq(user_id)
        expect(training_review.step_id).to eq(step_id)
        expect(training_review.feedback_grade).to be_nil
      end

      context 'when insufficient parameters are given for a submitted review' do
        let(:additional_params) { super().except(:submitted).merge(optionIDs: []) }

        before do
          training_review.submitted = true
          training_review.optionIDs = get_valid_rubrics(peer_assessment)
          training_review.save!
        end

        it 'rejects the update' do
          skip 'Adding a validation for this requires rewriting the factories / test state'
          modification
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'with the training opened' do
        before do
          # Unsubmitted sample reviews would be deleted when transitioning
          # into the training phase, so we mark it as submitted here.
          training_review.update(submitted: true)

          training_step = peer_assessment.steps[1]
          fulfill_training_requirements peer_assessment, training_step
          training_step.open = true
          training_step.save!
        end

        it 'rejects the update' do
          modification
          expect(response).to have_http_status :unprocessable_entity
        end

        it 'does not change the training review' do
          expect { modification }.not_to change { training_review }
        end
      end

      context 'text with file upload references' do
        let(:additional_params) { {id: review.id, text: 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'} }

        it 'stores valid upload and creates a new peerassessment' do
          stub_request(
            :head,
            'https://s3.xikolo.de/xikolo-uploads/' \
            'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
          ).and_return(
            status: 200,
            headers: {
              'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_review_text',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                           /assessments/[0-9a-zA-Z]+
                           /reviews/[0-9a-zA-Z]+
                           /rtfiles/[0-9a-zA-Z]+/foo.jpg}x
          stub_request(:head, store_regex).and_return(status: 404)
          stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
          expect { modification; review.reload }.to change(review, :text)
          expect(review.text).to include 's3://xikolo-peerassessment/assessments'
        end

        it 'rejects invalid upload and does not creates a new peerassessment' do
          stub_request(
            :head,
            'https://s3.xikolo.de/xikolo-uploads/' \
            'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
          ).and_return(
            status: 200,
            headers: {
              'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_review_text',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )

          modification

          expect(response).to have_http_status :unprocessable_entity
          expect(json['errors']).to eq 'text' => ['rtfile_rejected']
        end

        it 'rejects upload on storage errors' do
          stub_request(
            :head,
            'https://s3.xikolo.de/xikolo-uploads/' \
            'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
          ).and_return(
            status: 200,
            headers: {
              'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_review_text',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                           /assessments/[0-9a-zA-Z]+
                           /reviews/[0-9a-zA-Z]+
                           /rtfiles/[0-9a-zA-Z]+/foo.jpg}x
          stub_request(:head, store_regex).and_return(status: 404)
          stub_request(:put, store_regex).and_return(status: 503)

          modification

          expect(response).to have_http_status :unprocessable_entity
          expect(json['errors']).to eq 'text' => ['rtfile_error']
        end
      end

      context 'with old file references' do
        let(:additional_params) { {id: review.id, text: 'No content'} }

        before do
          review.update text: "Headline\ns3://xikolo-peerassessment/assessments/1/reviews/2/rtfiles/3/test.pdf"
        end

        it 'deletes no-longer referenced files' do
          cleanup_stub = stub_request(
            :delete,
            'https://s3.xikolo.de/xikolo-peerassessment/assessments/1/reviews/2/rtfiles/3/test.pdf'
          ).and_return(status: 200)

          expect { modification; review.reload }.to change(review, :text)
          expect(review.text).not_to include 's3://xikolo-peerassessment/assessments'
          expect(cleanup_stub).to have_been_requested
        end
      end
    end

    # rubocop:disable RSpec/AnyInstance
    describe 'grade computation' do
      let(:additional_params) do
        {
          id: review.id,
          text: 'New Text',
        }
      end

      it 'does not trigger grade computation' do
        expect_any_instance_of(Grade).not_to receive(:compute_grade)
        modification
      end

      context 'after deadline passed' do
        before { peer_assessment.grading_step.update! deadline: 1.day.ago }

        let(:grade) { submission.grade }

        it 'triggers grade computation' do
          expect_any_instance_of(Grade).to receive(:compute_grade).once
          modification
        end

        context 'with team submissions' do
          before do
            create(:submission, :with_pool_entries, shared_submission:)
          end

          it 'finds multiple submissions' do
            expect(submission.team_submissions).to have(2).items
          end

          context 'with stubs' do
            let(:grade1) { instance_double(Grade) }
            let(:grade2) { instance_double(Grade) }
            let(:submission1) { instance_double(Submission, grade: grade1) }
            let(:submission2) { instance_double(Submission, grade: grade2) }

            before do
              allow_any_instance_of(Submission).to receive(:team_submissions)
                .and_return([submission1, submission2])
            end

            it 'triggers grade computation on both submissions' do
              expect(grade1).to receive(:compute_grade).once
              expect(grade2).to receive(:compute_grade).once
              modification
            end
          end
        end
      end
    end
    # rubocop:enable all
  end

  describe '#destroy' do
    subject(:deletion) { delete :destroy, params: }

    before { shared_submission.update submitted: true }

    let!(:review) do
      create(:review,
        submission_id: submission.id,
        step: peer_assessment.steps[2],
        user_id: SecureRandom.uuid,
        text:)
    end

    let!(:training_review) do
      create(:review, :as_train_review,
        submission_id: submission.id,
        step: peer_assessment.steps[1],
        user_id: SecureRandom.uuid,
        text:)
    end
    let(:text) { 'Important Review' }

    describe 'with a valid id' do
      context 'which is a training review id' do
        let(:additional_params) { {id: training_review} }

        it 'deletes the review' do
          deletion
          expect(Review.exists?(training_review.id)).to be(false)
        end

        it 'changes the amount of existing reviews' do
          expect do
            deletion
          end.to change { Review.all.size }.by(-1)
        end
      end

      context 'which is not a training review id' do
        let(:additional_params) { {id: review.id} }

        it 'does not change the amount of reviews' do
          expect do
            deletion
          end.not_to change { Review.all.size }
        end
      end
    end

    describe 'without a valid id' do
      let(:invalid_id) { SecureRandom.uuid }
      let(:additional_params) { {id: invalid_id} }

      it 'does nothing' do
        expect do
          deletion
        end.not_to change { Review.all.size }

        expect(json.size).to eq(0)
      end
    end

    context 'with referenced file references' do
      let(:text) { "Headline\ns3://xikolo-peerassessment/assessments/1/reviews/2/rtfiles/3/test.pdf" }

      it 'removes these now obsolete files if review is deleted' do
        cleanup_stub = stub_request(
          :delete,
          'https://s3.xikolo.de/xikolo-peerassessment/assessments/1/reviews/2/rtfiles/3/test.pdf'
        ).and_return(status: 200)

        delete :destroy, params: {id: training_review.id, format: :json}
        expect(cleanup_stub).to have_been_requested
      end

      it 'does removes these now obsolete files if review is not deleted' do
        cleanup_stub = stub_request(
          :delete,
          'https://s3.xikolo.de/xikolo-peerassessment/assessments/1/reviews/2/rtfiles/3/test.pdf'
        ).and_return(status: 200)

        delete :destroy, params: {id: review.id, format: :json}
        expect(cleanup_stub).not_to have_been_requested
      end
    end
  end
end
