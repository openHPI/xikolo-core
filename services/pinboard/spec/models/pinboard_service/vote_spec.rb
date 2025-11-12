# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Vote, type: :model do
  subject(:vote) { build(:'pinboard_service/vote') }

  it 'has a valid factory' do
    expect(vote).to be_valid
  end

  describe 'create' do
    it 'publishes an event for newly created vote' do
      # Avoid publication of the question
      question = create(:'pinboard_service/question')
      vote.votable = question

      expect(Msgr).to receive(:publish) do |event, opts|
        expect(event).to eq \
          id: vote.id,
          value: vote.value,
          votable_id: vote.votable_id,
          votable_type: vote.votable_type,
          created_at: vote.created_at.iso8601,
          updated_at: vote.updated_at.iso8601,
          user_id: vote.user_id,
          votable_user_id: vote.votable.user_id,
          course_id: vote.votable.course_id
        expect(opts).to eq to: 'xikolo.pinboard.vote.create'
      end
      vote.save
    end
  end

  it { is_expected.to accept_values_for(:value, -1, 0, 1, '-1', '0', '1') }
  it { is_expected.not_to accept_values_for(:value, 2, 5, -10) }
end
