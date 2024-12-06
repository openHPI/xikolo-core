# frozen_string_literal: true

require 'spec_helper'

describe ReviewHelper, type: :helper do
  let(:user_id) { SecureRandom.uuid }
  let(:ta_id) { SecureRandom.uuid }

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

    Stub.request(
      :account, :get, "/users/#{ta_id}"
    ).to_return Stub.json({
      id: user_id,
      avatar_url: 'https://s3.xikolo.de/xikolo-public/avatar/003.jpg',
      email: 'test@example.de',
      permissions_url: "/permissions?user_id=#{ta_id}",
    })

    Stub.request(
      :account, :get, "/permissions?user_id=#{ta_id}"
    ).to_return Stub.json(['peerassessment.submission.manage'])
  end

  describe '#get_sample' do
    let(:assessment) { create(:peer_assessment, :with_steps) }
    let(:pool) { create(:resource_pool, peer_assessment: assessment, purpose: 'training') }
    let(:action) { -> { helper.get_sample pool, assessment.training_step, user_id } }

    before { assessment.update resource_pools: [pool] }

    context 'with normal submissions' do
      before { create_list(:pool_entry, 2, resource_pool: pool, available_locks: 1) }

      it 'returns multiple entries' do
        action.call
        expect(action.call).to be_a Review
      end
    end

    context 'with team submission' do
      let(:shared_submission) { create(:shared_submission, peer_assessment: assessment) }
      let(:submissions) { create_list(:submission, 2, shared_submission:) }

      before { submissions.map(&:handle_training_pool_entry) }

      it 'returns one entry' do
        action.call
        expect(action.call).to be_nil
      end

      it 'changes the locks of associated entries' do
        action.call
        expect(PoolEntry.where(available_locks: 0).count).to eq 2
      end
    end
  end

  describe '#retrieve_student_training_sample' do
    subject(:sample) { -> { helper.retrieve_student_training_sample(assessment.id, user_id) } }

    let!(:assessment) { create(:peer_assessment, :with_steps) }

    let!(:submission) do
      ss = create(:shared_submission, peer_assessment: assessment)
      create(:submission, shared_submission: ss)
    end
    let!(:user_submission) do
      ss = create(:shared_submission, peer_assessment: assessment)
      create(:submission, shared_submission: ss, user_id:)
    end

    before do
      # rubocop:disable RSpec/AnyInstance
      # rubocop:disable RSpec/StubbedMock
      expect_any_instance_of(Training).to receive(:can_be_opened?).and_return(true)
      assessment.training_step.update! open: true
      # rubocop:enable RSpec/AnyInstance
      # rubocop:enable RSpec/StubbedMock
      # could interfere with training sample selection
      assessment.grading_step.update required_reviews: 0

      Review.create! submission:,
        step: assessment.training_step,
        train_review: true,
        user_id: ta_id,
        submitted: true
    end

    it 'returns one review' do
      expect(sample.call).to have(1).item
    end

    context 'with only own submission remaining' do
      before do
        review = sample.call.first
        review.update! submitted: true
      end

      it 'does not return the own review' do
        expect(sample.call).to be_empty
      end
    end

    context 'with team submission' do
      before do
        user_submission.update! shared_submission_id: submission.shared_submission_id
      end

      it 'does not let you review submissions of a team member' do
        expect(sample.call).to be_empty
      end
    end

    context 'with only own and finished submission remaining' do
      before do
        # Create another submission
        create(:submission, shared_submission: submission.shared_submission)

        review = sample.call.first
        review.update! submitted: true
      end

      it 'does not return the own review' do
        expect(sample.call).to be_empty
      end
    end

    context 'with additional attempts' do
      let(:another_submission) do
        ss = create(:shared_submission, peer_assessment: assessment)
        create(:submission, shared_submission: ss)
      end

      before do
        assessment.training_step.update required_reviews: 1
        assessment.grading_step.update required_reviews: 1

        Review.create! submission: another_submission,
          step: assessment.training_step,
          train_review: true,
          user_id: ta_id,
          submitted: true

        review = sample.call.first
        review.update! submitted: true
      end

      it 'does not return further reviews' do
        expect(sample.call).to be_empty
      end
    end
  end

  describe '#retrieve_grading_review' do
    subject(:retrieve_review) { -> { helper.retrieve_grading_review(assessment.id, user_id) } }

    let!(:assessment) { create(:peer_assessment, :with_steps) }
    let!(:submission) do
      ss = create(:shared_submission, peer_assessment: assessment)
      create(:submission, shared_submission: ss)
    end
    let!(:user_submission) do
      ss = create(:shared_submission, peer_assessment: assessment)
      create(:submission, shared_submission: ss, user_id:)
    end

    before do
      Submission.find_each(&:handle_grading_pool_entry)
    end

    it 'returns one review' do
      expect(retrieve_review.call).to have(1).item
    end

    context 'with only own submission remaining' do
      before do
        review = retrieve_review.call.first
        review.update! submitted: true
      end

      it 'does not return the own review' do
        expect(retrieve_review.call).to be_empty
      end
    end

    context 'with team submission' do
      before do
        user_submission.update! shared_submission_id: submission.shared_submission_id
      end

      it 'does not let you review submissions of a team member' do
        expect(retrieve_review.call).to be_empty
      end
    end

    context 'with only own and finished submission remaining' do
      let(:another_submission) do
        create(:submission, shared_submission: submission.shared_submission)
      end

      before do
        another_submission.handle_grading_pool_entry

        review = retrieve_review.call.first
        review.update! submitted: true
      end

      it 'does not return the own review' do
        expect(retrieve_review.call).to be_empty
      end
    end
  end

  describe '#get_team_evaluation_reviews' do
    subject { action.call }

    let(:assessment) { create(:peer_assessment, :with_steps) }
    let(:shared_submission) { create(:shared_submission, peer_assessment: assessment) }
    let!(:team_submissions) do
      create_list(:submission, 3, shared_submission:)
    end
    let(:action) { -> { helper.get_team_evaluation_reviews(assessment.id, user_id) } }

    before do
      create(:submission, shared_submission:, user_id:)
    end

    it { is_expected.to have(3).items }

    it 'returns reviews for submissions of my team members' do
      team_submission_ids = team_submissions.map(&:id)
      expect(action.call.map(&:submission_id)).to match team_submission_ids
    end

    it 'returns the same reviews' do
      reviews = action.call
      expect(action.call).to match reviews
    end

    context 'with submitted reviews' do
      before do
        reviews = action.call
        reviews.first.update submitted: true
      end

      it { is_expected.to have(3).items }
    end
  end
end
