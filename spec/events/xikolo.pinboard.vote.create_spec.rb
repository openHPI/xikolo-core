# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.pinboard.vote.create' do
  subject(:new_vote) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:course) { create(:course) }
  let(:user_id) { user2.id }
  let(:score_attributes) { attributes_for(:gamification_score, :answer_vote, course_id: course.id, user_id: user.id) }
  let(:votable_type) { 'Answer' }
  let(:payload) do
    {
      id: generate(:uuid).to_s,
      value: 1,
      votable_id: score_attributes[:data][:votable_id],
      votable_type:,
      votable_user_id: score_attributes[:user_id],
      user_id:,
      course_id: score_attributes[:course_id],
    }
  end
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.pinboard.vote.create' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
  end

  context 'for answer' do
    it 'creates a new score' do
      expect { new_vote }.to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with existing score' do
      let!(:score) { create(:gamification_score, :answer_vote, data: score_attributes[:data]) }
      let(:user_id) { score.user_id }

      before { expect(Gamification::Score.count).to eq 1 }

      it 'does not create a new score' do
        expect { new_vote }.not_to change(Gamification::Score, :count)
      end
    end
  end

  context 'for question' do
    let(:score_attributes) { attributes_for(:gamification_score, :question_vote, course_id: course.id, user_id: user.id) }
    let(:votable_type) { 'Question' }

    it 'creates a new score' do
      expect { new_vote }.to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with existing score' do
      let!(:score) { create(:gamification_score, :question_vote, course:, user:) }
      let(:user_id) { score.user_id }

      before { expect(Gamification::Score.count).to eq 1 }

      it 'does not create a new score' do
        expect { new_vote }.not_to change(Gamification::Score, :count)
      end
    end
  end
end
