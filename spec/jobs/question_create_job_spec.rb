# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuestionCreateJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let!(:course) { create(:course) }
  let!(:user)   { create(:'account_service/user') }

  let(:user_id) { user.id }

  let(:score_attributes) do
    attributes_for(
      :gamification_score,
      :question_create,
      course_id: course.id
    )
  end

  let(:payload) do
    {
      id: score_attributes[:data][:question_id],
      title: 'Title',
      text: 'Text',
      user_id: user_id,
      course_id: score_attributes[:course_id],
      technical: false,
    }
  end

  it 'creates a new score' do
    expect { perform_job }
      .to change(Gamification::Score, :count)
      .from(0).to(1)
  end

  context 'with existing score' do
    let!(:score) do
      create(
        :gamification_score,
        :question_create,
        data: score_attributes[:data]
      )
    end

    let(:user_id) { score.user_id }

    before { expect(Gamification::Score.count).to eq 1 }

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end

  context 'with technical question' do
    let(:payload) { super().merge(technical: true) }

    before do
      create(:gamification_score, :question_create)
      expect(Gamification::Score.count).to eq 1
    end

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end
end
