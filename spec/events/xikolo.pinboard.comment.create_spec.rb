# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.pinboard.comment.create' do
  subject(:new_comment) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:course) { create(:course) }
  let!(:user) { create(:user) }
  let(:user_id) { user.id }
  let(:score_attributes) { attributes_for(:gamification_score, :comment_create, user_id: user.id, course_id: course.id) }
  let(:payload) do
    {
      id: score_attributes[:data][:comment_id],
      text: 'Text',
      user_id:,
      course_id: score_attributes[:course_id],
      technical: false,
    }
  end
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.pinboard.comment.create' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
  end

  it 'creates a new score' do
    expect { new_comment }.to change(Gamification::Score, :count).from(0).to(1)
  end

  context 'with existing score' do
    let!(:score) { create(:gamification_score, :comment_create, course:, user:, data: score_attributes[:data]) }
    let(:user_id) { score.user_id }

    before { expect(Gamification::Score.count).to eq 1 }

    it 'does not create a new score' do
      expect { new_comment }.not_to change(Gamification::Score, :count)
    end
  end

  context 'with technical question' do
    let(:payload) { super().merge technical: true }

    before do
      create(:gamification_score, :comment_create)
      expect(Gamification::Score.count).to eq 1
    end

    it 'does not create a new score' do
      expect { new_comment }.not_to change(Gamification::Score, :count)
    end
  end
end
