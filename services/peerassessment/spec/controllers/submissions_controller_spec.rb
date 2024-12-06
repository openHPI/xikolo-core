# frozen_string_literal: true

require 'spec_helper'

describe SubmissionsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:params) { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:peer_assessment) { create(:peer_assessment, :with_steps) }

  describe '#index' do
    subject(:index) { get :index, params: }

    describe 'without additional params' do
      before do
        5.times do
          create(:submission,
            :with_pool_entries,
            peer_assessment:)
        end
      end

      it 'is successful' do
        index
        expect(response).to be_successful
      end

      it 'retrieves all submissions' do
        index
        expect(json.size).to eq(Submission.all.size)
      end

      describe 'for one specific peer assessment' do
        let(:additional_params) { {peer_assessment_id: peer_assessment.id} }

        it 'retrieves the correct amount of reviews' do
          index
          expect(json.size).to eq(5)
        end
      end

      describe 'for an invalid peer_assessment id' do
        let(:additional_params) { {peer_assessment_id: SecureRandom.uuid} }

        it 'retrieves nothing' do
          index
          expect(json.size).to eq(0)
        end
      end
    end

    describe 'with user_filter param' do
      let!(:user) { {'id' => SecureRandom.uuid} }
      let!(:submission_with_user) do
        create(:submission,
          :with_pool_entries,
          user_id: user['id'],
          peer_assessment:)
      end
      let!(:submission_with_random_user) do
        create(:submission,
          :with_pool_entries,
          peer_assessment:)
      end
      let(:additional_params) { {peer_assessment_id: peer_assessment.id, user_filter: 'Test User'} }

      before do
        Stub.service(
          :account,
          users_url: '/users'
        )

        Stub.request(
          :account, :get, '/users',
          query: {query: 'Test User'}
        ).to_return Stub.json([user])
      end

      it 'is successful' do
        index
        expect(response).to be_successful
      end

      it 'retrieves submission of the user' do
        index
        expect(json.pluck('id')).to include(submission_with_user.id)
      end

      it 'does not retrieves submission of random user' do
        index
        expect(json.pluck('id')).not_to include(submission_with_random_user.id)
      end
    end

    describe 'with search params' do
      let!(:best_nominations_submission) do
        create(:submission,
          :with_pool_entries,
          :with_nominations,
          :with_grade,
          :with_avg_rating,
          peer_assessment:,
          submitted: true,
          nominations: 5,
          points: 5.0,
          rating: 3)
      end

      let!(:best_grade_submission) do
        create(:submission,
          :with_pool_entries,
          :with_nominations,
          :with_grade,
          :with_avg_rating,
          peer_assessment:,
          submitted: true,
          nominations: 3,
          points: 8.0,
          rating: 3)
      end

      let!(:best_rating_submission) do
        create(:submission,
          :with_pool_entries,
          :with_nominations,
          :with_grade,
          :with_avg_rating,
          peer_assessment:,
          submitted: false,
          nominations: 3,
          points: 5.0,
          rating: 5)
      end

      context('order by: avg_rating - nominations - points') do
        let(:additional_params) do
          {
            peer_assessment_id: peer_assessment.id,
              include_votes: true,
              first: 'avg_rating',
              second: 'nominations',
              third: 'points',
          }
        end

        it 'is successful' do
          index
          expect(response).to be_successful
        end

        it 'retrieves all submissions' do
          index
          expect(json.size).to eq(Submission.all.size)
        end

        it 'orders correctly' do
          index
          expect(json.pluck('id'))
            .to eq([best_rating_submission.id, best_nominations_submission.id, best_grade_submission.id])
        end
      end

      context('order by: points - avg_rating - blank') do
        let(:additional_params) do
          {
            peer_assessment_id: peer_assessment.id,
              include_votes: true,
              first: 'points',
              second: 'avg_rating',
              third: '',
          }
        end

        it 'is successful' do
          index
          expect(response).to be_successful
        end

        it 'retrieves all submissions' do
          index
          expect(json.size).to eq(Submission.all.size)
        end

        it 'orders correctly' do
          index
          expect(json.pluck('id'))
            .to eq([best_grade_submission.id, best_rating_submission.id, best_nominations_submission.id])
        end
      end

      context('order by: nominations - blank - blank and only submitted') do
        let(:additional_params) do
          {
            peer_assessment_id: peer_assessment.id,
              include_votes: true,
              first: 'nominations',
              second: '',
              third: '',
              final_only: true,
          }
        end

        it 'is successful' do
          index
          expect(response).to be_successful
        end

        it 'does not include unsubmitted submission' do
          index
          expect(json.pluck('id'))
            .not_to include(best_rating_submission.id)
        end

        it 'orders correctly' do
          index
          expect(json.pluck('id'))
            .to eq([best_nominations_submission.id, best_grade_submission.id])
        end
      end

      context('order by: points - blank - blank and gallery only') do
        let(:additional_params) do
          {
            peer_assessment_id: peer_assessment.id,
              include_votes: true,
              first: 'points',
              second: '',
              third: '',
              gallery_only: true,
          }
        end

        before do
          peer_assessment.gallery_entries = [best_grade_submission.shared_submission_id, best_rating_submission.shared_submission_id]
          peer_assessment.save
          peer_assessment.reload
        end

        it 'is successful' do
          index
          expect(response).to be_successful
        end

        it 'does not include submissions not included in gallery' do
          index
          expect(json.pluck('id'))
            .not_to include(best_nominations_submission.id)
        end

        it 'orders correctly' do
          index
          expect(json.pluck('id'))
            .to eq([best_grade_submission.id, best_rating_submission.id])
        end
      end

      context('order by: blank - blank - blank and gallery only and final only') do
        let(:additional_params) do
          {
            peer_assessment_id: peer_assessment.id,
              include_votes: true,
              first: '',
              second: '',
              third: '',
              gallery_only: true,
              final_only: true,
          }
        end

        before do
          peer_assessment.gallery_entries = [best_grade_submission.shared_submission_id, best_rating_submission.shared_submission_id]
          peer_assessment.save
          peer_assessment.reload
        end

        it 'is successful' do
          index
          expect(response).to be_successful
        end

        it 'only includes best grade submission' do
          index
          expect(json.pluck('id'))
            .to eq([best_grade_submission.id])
        end
      end
    end
  end

  describe '#show' do
    subject(:show) { get :show, params: }

    let(:shared_submission) do
      create(:shared_submission,
        :as_submitted,
        peer_assessment_id: peer_assessment.id)
    end
    let(:submission) do
      create(:submission,
        :with_pool_entries,
        user_id: SecureRandom.uuid,
        shared_submission:)
    end

    describe 'with a valid id' do
      let(:additional_params) { {id: submission.id} }

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
        expect(json['id']).to eq(submission.id)
      end
    end

    describe 'with an invalid id' do
      let(:invalid_id) { SecureRandom.uuid }
      let(:additional_params) { {id: invalid_id} }

      it 'returns nothing' do
        show
        expect(json).to be_empty
      end

      it 'is not successful' do
        show
        expect(response).not_to be_successful
      end
    end
  end

  describe '#create' do
    subject(:post_create) { post :create, params: }

    context 'with everything given in params to create a submission' do
      let(:additional_params) do
        {
          text: 'Test text',
          submitted: false,
          disallowed_sample: false,
          user_id: SecureRandom.uuid,
          peer_assessment_id: peer_assessment.id,
        }
      end

      it 'is successful' do
        post_create
        expect(response).to be_successful
      end

      it 'creates a submission' do
        expect do
          post_create
        end.to change { Submission.all.size }.by(1)
      end
    end

    context 'with missing parameters' do
      let(:additional_params) do
        {
          text: 'Test text',
          submitted: false,
          disallowed_sample: false,
          user_id: SecureRandom.uuid,
        }
      end

      it 'is not successful' do
        post_create
        expect(response).to be_client_error
      end

      it 'does not create a submission' do
        expect do
          post_create
        end.not_to change { Submission.all.size }
      end
    end
  end

  describe '#update' do
    subject(:update) { post :update, params: }

    context 'on a submitted submission' do
      let(:shared_submission) do
        create(:shared_submission,
          :as_submitted,
          peer_assessment:)
      end
      let(:submission) do
        create(:submission,
          :with_pool_entries,
          user_id: SecureRandom.uuid,
          shared_submission:)
      end

      let(:additional_params) { {id: submission.id, text: 'New TEXT!'} }

      it 'rejects the update' do
        update
        expect(response).not_to be_successful
      end

      it 'includes the error in the response' do
        update
        expect(JSON.parse(response.body)).to eq(
          'base' => ['You can not update a submitted submission']
        )
      end
    end

    context 'on an unsubmitted submission' do
      let(:shared_submission) do
        create(:shared_submission,
          peer_assessment:)
      end

      let(:submission) do
        create(:submission,
          user_id: SecureRandom.uuid,
          shared_submission:)
      end

      let(:additional_params) do
        {
          id: submission.id,
          text: 'New TEXT!',
          additional_info: 'New info!',
          submitted: true,
          user_id: SecureRandom.uuid,
          peer_assessment_id: SecureRandom.uuid,
        }
      end

      it 'is successful' do
        update
        expect(response).to be_successful
      end

      it 'only updates allowed attributes' do
        user_id = submission.user_id
        peer_assessment_id = submission.peer_assessment_id

        update

        expect(submission.reload.text).to eq('New TEXT!')
        expect(submission.submitted).to be(true)
        expect(submission.user_id).to eq(user_id)
        expect(submission.peer_assessment_id).to eq(peer_assessment_id)
      end

      it 'does not create a training pool entry if it is a disallowed sample' do
        additional_params[:disallowed_sample] = true
        training_pool = peer_assessment.resource_pools.find_by(purpose: 'training')

        update

        expect(PoolEntry.where(resource_pool_id: training_pool.id)).to be_empty
      end
    end
  end
end
