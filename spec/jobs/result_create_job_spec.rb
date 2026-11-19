# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResultCreateJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let!(:user) { create(:'account_service/user') }
  let!(:course) { create(:course) }

  let(:score_attributes) do
    attributes_for(:gamification_score, :take_exam,
      course_id: course.id,
      user_id: user.id)
  end

  let(:points) { 1 }
  let(:max_points) { 10 }
  let(:deadline) { DateTime.iso8601('2015-01-26T04:05:06+07:00') }

  let(:payload) do
    {
      id: score_attributes[:data][:result_id],
      user_id: user.id,
      course_id: score_attributes[:course_id],
      item_id: score_attributes[:data][:item_id],
      section_id: score_attributes[:data][:section_id],
      exercise_type: exercise_type,
      submission_deadline: deadline,
      created_at: DateTime.iso8601('2015-01-20T04:05:06+07:00'),
      points: points,
      max_points: max_points,
    }
  end

  context 'for early submission' do
    let(:exercise_type) { 'main' }

    it 'creates a new score' do
      expect { perform_job }
        .to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with correctly created score' do
      before { perform_job }

      it 'the score has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'the score has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'take_exam'
      end
    end

    context 'with existing score' do
      before do
        create(:gamification_score, :take_exam,
          user: user,
          course: course,
          data: score_attributes[:data])
      end

      it 'does not create a new score' do
        expect { perform_job }
          .not_to change(Gamification::Score, :count)
      end
    end

    context 'without a submission deadline' do
      let(:deadline) { nil }

      it 'does not create a new score' do
        expect { perform_job }
          .not_to change(Gamification::Score, :count)
      end
    end
  end

  context 'for taking a selftest' do
    let(:exercise_type) { 'selftest' }

    let(:score_attributes) do
      attributes_for(:gamification_score, :take_selftest,
        course_id: course.id,
        user_id: user.id)
    end

    it 'creates a new score' do
      expect { perform_job }
        .to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with correctly created score' do
      before { perform_job }

      it 'the score has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'the score has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'take_selftest'
      end
    end

    context 'with existing score' do
      before do
        create(:gamification_score, :take_selftest,
          user: user,
          course: course,
          data: score_attributes[:data])
      end

      it 'does not create a new score' do
        expect { perform_job }
          .not_to change(Gamification::Score, :count)
      end
    end
  end

  context 'with wrong exercise type' do
    let(:exercise_type) { 'bonus' }

    it 'does not create a new score' do
      expect { perform_job }
        .not_to change(Gamification::Score, :count)
    end
  end
end
