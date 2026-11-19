# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VoteCreateJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let!(:user) { create(:'account_service/user') }
  let!(:user2) { create(:'account_service/user') }
  let!(:course) { create(:course) }

  let(:user_id) { user2.id }

  let(:score_attributes) do
    attributes_for(
      :gamification_score,
      :answer_vote,
      course_id: course.id,
      user_id: user.id
    )
  end

  let(:votable_type) { 'Answer' }

  let(:payload) do
    {
      id: generate(:uuid).to_s,
      value: 1,
      votable_id: score_attributes[:data][:votable_id],
      votable_type: votable_type,
      votable_user_id: score_attributes[:user_id],
      user_id: user_id,
      course_id: score_attributes[:course_id],
    }
  end

  context 'for answer' do
    it 'creates a new score' do
      expect { perform_job }
        .to change(Gamification::Score, :count)
        .from(0).to(1)
    end

    context 'with existing score' do
      let!(:score) do
        create(
          :gamification_score,
          :answer_vote,
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
  end

  context 'for question' do
    let(:score_attributes) do
      attributes_for(
        :gamification_score,
        :question_vote,
        course_id: course.id,
        user_id: user.id
      )
    end

    let(:votable_type) { 'Question' }

    it 'creates a new score' do
      expect { perform_job }
        .to change(Gamification::Score, :count)
        .from(0).to(1)
    end

    context 'with existing score' do
      let!(:score) do
        create(
          :gamification_score,
          :question_vote,
          course: course,
          user: user
        )
      end

      let(:user_id) { score.user_id }

      before { expect(Gamification::Score.count).to eq 1 }

      it 'does not create a new score' do
        expect { perform_job }
          .not_to change(Gamification::Score, :count)
      end
    end
  end
end
