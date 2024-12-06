# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessment, type: :model do
  subject { assessment }

  let(:assessment_id) { SecureRandom.uuid }
  let!(:assessment)   { create(:peer_assessment, :with_steps, :with_deterministic_rubrics, id: assessment_id) }
  let(:user_id)       { SecureRandom.uuid }

  describe 'validity' do
    it 'is valid' do
      expect(assessment).to be_valid
    end
  end

  it 'has the correct amount of steps' do
    expect(assessment.steps.count).to eq(5)
  end

  it 'has the correct amount of rubrics' do
    expect(assessment.rubrics.count).to eq(3)
  end

  it 'has resource pools without entries' do
    expect(assessment.resource_pools).not_to be_empty
    expect(PoolEntry.all.size).to eq(0)
  end

  it 'is not passed' do
    expect(assessment.passed?).to be(false)
  end

  it 'has a valid amount of maximum points' do
    expect(assessment.max_points).to eq 9
  end

  #
  # context 'user started the assessment' do
  #   let!(:submission) { FactoryBot.create(:submission, peer_assessment_id: assessment_id, user_id: user_id) }
  #
  #   it 'should have the submission step as current step' do
  #     submission # Necessary for the test to pass...
  #     expect(assessment.current_step user_id).to eq(assessment.steps.first)
  #   end
  #
  #   context 'user submits his solution' do
  #
  #     it 'should have a finished submission step' do
  #       submission.submitted = true
  #       submission.save
  #
  #       expect(assessment.steps.first.finished? user_id).to eq(true)
  #     end
  #
  #     it 'should advance to the next step' do
  #       submission.submitted = true
  #       submission.save
  #
  #       expect(assessment.current_step user_id).to eq(assessment.steps.second)
  #     end
  #   end
  # end
  #
  # context 'assessment passed' do
  #   it 'should be marked as passed' do
  #     step = assessment.steps.last
  #     step.deadline = 1.day.ago
  #     step.save
  #
  #     expect(assessment.passed?).to eq(true)
  #   end
  # end
  #
  #
  # describe PeerAssessment, ".cleanup_expired_reviews" do
  #   let!(:submission)      { FactoryBot.create(:submission, :as_submitted, peer_assessment_id: assessment_id, user_id: SecureRandom.uuid) }
  #
  #   let!(:review)          { FactoryBot.create :review, submission_id: submission.id, user_id: SecureRandom.uuid, step: assessment.steps[2] }
  #   let!(:train_review)    { FactoryBot.create :review, submission_id: submission.id, user_id: SecureRandom.uuid, step: assessment.steps[1] }
  #   let!(:ta_train_review) { FactoryBot.create :review, :as_train_review, submission_id: submission.id, user_id: SecureRandom.uuid, step: assessment.steps[1] }
  #
  #   let!(:train_pool_entry) { FactoryBot.create :pool_entry, submission: submission, available_locks: 0, resource_pool: assessment.resource_pools.first }
  #   let!(:pool_entry)       { FactoryBot.create :pool_entry, submission: submission, available_locks: 2, resource_pool: assessment.resource_pools[1] }
  #
  #   it 'should not clean up reviews' do
  #     count = Review.all.count
  #     PeerAssessment.cleanup_expired_reviews
  #     expect(Review.all.count).to eq(count)
  #   end
  #
  #   it 'should remove the TA train review' do
  #     ta_train_review.deadline = 10.minutes.ago
  #     ta_train_review.save
  #
  #     count = Review.all.count
  #     locks = train_pool_entry.available_locks
  #
  #     PeerAssessment.cleanup_expired_reviews
  #
  #     expect(Review.all.reload.count).to eq(count - 1)
  #     expect(train_pool_entry.reload.available_locks).to eq(locks + 1)
  #   end
  #
  #   it 'should not remove the students train review' do
  #     train_review.deadline = 10.minutes.ago
  #     train_review.save
  #
  #     count = Review.all.count
  #     locks = train_pool_entry.available_locks
  #
  #     PeerAssessment.cleanup_expired_reviews
  #
  #     expect(Review.all.reload.count).to eq(count)
  #     expect(train_pool_entry.reload.available_locks).to eq(locks) # Should not affect the pool at all
  #   end
  #
  #   it 'should remove the students regular review' do
  #     review.deadline = 10.minutes.ago
  #     review.save
  #
  #     count = Review.all.count
  #     locks = pool_entry.available_locks
  #
  #     PeerAssessment.cleanup_expired_reviews
  #
  #     expect(Review.all.reload.count).to eq(count - 1)
  #     expect(pool_entry.reload.available_locks).to eq(locks + 1)
  #   end
  # end
end
