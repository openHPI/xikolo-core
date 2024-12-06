# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.pinboard.question.update' do
  subject(:update_question) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:course) { create(:course) }
  let!(:user) { create(:user) }
  let!(:user2) { create(:user) }
  let(:question_author_id) { user.id }
  let(:question_id) { generate(:uuid).to_s }
  let(:accepted_answer_id) { generate(:uuid).to_s }
  let(:payload) do
    {
      id: question_id,
      accepted_answer_id:,
      accepted_answer_user_id: user2.id, # the author of the answer that was accepted
      user_id: question_author_id,
      course_id: course.id,
      technical: false,
    }
  end
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.pinboard.question.update' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
  end

  it 'creates a new score' do
    expect { update_question }.to change(Gamification::Score, :count).from(0).to(1)
  end

  context "when accepting an answer by the question's author" do
    let(:payload) { super().merge(accepted_answer_user_id: question_author_id) }

    it 'does not create a new score' do
      expect { update_question }.not_to change(Gamification::Score, :count).from(0)
    end
  end

  context 'update without accepted answer' do
    let(:payload) do
      {
        id: question_id,
        accepted_answer_id: nil,
        user_id: question_author_id,
        course_id: course.id,
        technical: false,
      }
    end

    it 'does not create a new score if accepted_answer is nil' do
      expect { update_question }.not_to change(Gamification::Score, :count)
    end
  end

  context 'with existing score' do
    let!(:score) { create(:gamification_score, :accepted_answer, course:, user:, data: {accepted_answer_id:}) }
    let(:question_author_id) { score.user_id }

    it 'does not create a new score' do
      expect { update_question }.not_to change(Gamification::Score, :count).from(1)
    end
  end

  context 'with technical question' do
    let(:payload) { super().merge technical: true }

    before { create(:gamification_score, :accepted_answer, course:, user:) }

    it 'does not create a new score' do
      expect { update_question }.not_to change(Gamification::Score, :count).from(1)
    end
  end
end
