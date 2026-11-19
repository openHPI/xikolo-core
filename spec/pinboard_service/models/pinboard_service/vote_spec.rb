# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Vote, type: :model do
  subject(:vote) { build(:'pinboard_service/vote') }

  it 'has a valid factory' do
    expect(vote).to be_valid
  end

  describe 'create' do
    it 'enqueues a VoteCreateJob for newly created vote' do
      # Avoid publication of the question
      question = create(:'pinboard_service/question')
      vote.votable = question

      expect do
        vote.save
      end.to have_enqueued_job(VoteCreateJob).with(
        {
          id: kind_of(String),
          value: vote.value,
          votable_id: vote.votable_id,
          votable_type: vote.votable_type,
          created_at: kind_of(String),
          updated_at: kind_of(String),
          user_id: vote.user_id,
          votable_user_id: vote.votable.user_id,
          course_id: vote.votable.course_id,
        }
      )
    end
  end

  it { is_expected.to accept_values_for(:value, -1, 0, 1, '-1', '0', '1') }
  it { is_expected.not_to accept_values_for(:value, 2, 5, -10) }
end
