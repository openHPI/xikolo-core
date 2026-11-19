# frozen_string_literal: true

require 'spec_helper'

describe AnswerAcceptedJob do
  subject(:perform_job) { described_class.perform_now(payload) }

  let!(:course) { create(:course) }
  let!(:user) { create(:'account_service/user') }
  let!(:user2) { create(:'account_service/user') }

  let(:question_author_id) { user.id }
  let(:question_id) { generate(:uuid).to_s }
  let(:accepted_answer_id) { generate(:uuid).to_s }

  let(:payload) do
    {
      id: question_id,
      accepted_answer_id: accepted_answer_id,
      accepted_answer_user_id: user2.id, # author of accepted answer
      user_id: question_author_id,
      course_id: course.id,
      technical: false,
    }
  end

  it 'creates a new score' do
    expect { perform_job }
      .to change(Gamification::Score, :count).from(0).to(1)
  end

  context "when accepting an answer by the question's author" do
    let(:payload) { super().merge(accepted_answer_user_id: question_author_id) }

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
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

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end

  context 'with existing score' do
    let!(:score) do
      create(:gamification_score,
        :accepted_answer,
        course: course,
        user: user,
        data: {accepted_answer_id: accepted_answer_id})
    end

    let(:question_author_id) { score.user_id }

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end

  context 'with technical question' do
    let(:payload) { super().merge(technical: true) }

    before do
      create(:gamification_score, :accepted_answer, course: course, user: user)
    end

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end
end
