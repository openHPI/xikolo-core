# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.pinboard.question.create' do
  subject(:new_question) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:course) { create(:course) }
  let!(:user) { create(:user) }
  let(:user_id) { user.id }
  let(:score_attributes) { attributes_for(:gamification_score, :question_create, course_id: course.id) }
  let(:payload) do
    {
      id: score_attributes[:data][:question_id],
      title: 'Title',
      text: 'Text',
      user_id:,
      course_id: score_attributes[:course_id],
      technical: false,
    }
  end
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.pinboard.question.create' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
  end

  it 'creates a new score' do
    expect { new_question }.to change(Gamification::Score, :count).from(0).to(1)
  end

  context 'with existing score' do
    let!(:score) { create(:gamification_score, :question_create, data: score_attributes[:data]) }
    let(:user_id) { score.user_id }

    before { expect(Gamification::Score.count).to eq 1 }

    it 'does not create a new score' do
      expect { new_question }.not_to change(Gamification::Score, :count)
    end
  end

  context 'with technical question' do
    let(:payload) { super().merge technical: true }

    before do
      create(:gamification_score, :question_create)
      expect(Gamification::Score.count).to eq 1
    end

    it 'does not create a new score' do
      expect { new_question }.not_to change(Gamification::Score, :count)
    end
  end
end
