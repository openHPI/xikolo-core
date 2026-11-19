# frozen_string_literal: true

require 'spec_helper'

describe Course::Item::ProgressState do
  subject(:progress_state) do
    described_class.new(
      content_type:, exercise_type:, user_state:, user_points:, max_points:,
      deadline_passed:, pass_percentage:
    )
  end

  let(:content_type) { 'quiz' }
  let(:exercise_type) { 'main' }
  let(:user_state) { 'graded' }
  let(:user_points) { nil }
  let(:max_points) { 10.0 }
  let(:deadline_passed) { false }
  let(:pass_percentage) { nil }

  shared_examples 'marked as completed' do
    it { expect(progress_state).to be_marked }
  end

  shared_examples 'not marked as completed' do
    it { expect(progress_state).not_to be_marked }
  end

  %w[quiz lti_exercise].each do |type|
    context "for a gradable #{type}" do
      let(:content_type) { type }

      context 'that has not been submitted' do
        let(:user_state) { 'visited' }

        it_behaves_like 'not marked as completed'
      end

      context 'with less than 50% achieved points' do
        let(:user_points) { 4.9 }

        it_behaves_like 'not marked as completed'
      end

      context 'with 50% to 95% achieved points' do
        let(:user_points) { 5.0 }

        it_behaves_like 'marked as completed'
      end

      context 'with more than 95% achieved points' do
        let(:user_points) { 9.6 }

        it_behaves_like 'marked as completed'
      end

      context 'with no available points' do
        let(:user_state) { 'submitted' }
        let(:max_points) { 0 }

        it_behaves_like 'marked as completed'
      end
    end
  end

  context 'for a gradable CMI5 item' do
    let(:content_type) { 'cmi5' }
    let(:exercise_type) { 'selftest' }

    context 'that has not been submitted' do
      let(:user_state) { 'visited' }

      it_behaves_like 'not marked as completed'
    end

    context 'with less than 50% achieved points' do
      let(:user_points) { 4.9 }

      it_behaves_like 'not marked as completed'
    end

    context 'with 50% to 95% achieved points' do
      let(:user_points) { 5.0 }

      it_behaves_like 'marked as completed'
    end

    context 'with more than 95% achieved points' do
      let(:user_points) { 9.6 }

      it_behaves_like 'marked as completed'
    end
  end

  context 'for an LTI exercise whose submission deadline has passed' do
    let(:content_type) { 'lti_exercise' }
    let(:deadline_passed) { true }

    context 'that has not been submitted' do
      let(:user_state) { 'visited' }

      it_behaves_like 'not marked as completed'
    end

    context 'with less than 50% achieved points' do
      let(:user_points) { 4.9 }

      it_behaves_like 'marked as completed'
    end

    context 'with 50% to 95% achieved points' do
      let(:user_points) { 5.0 }

      it_behaves_like 'marked as completed'
    end

    context 'with more than 95% achieved points' do
      let(:user_points) { 9.6 }

      it_behaves_like 'marked as completed'
    end
  end

  context 'for an exam' do
    let(:exercise_type) { 'exam' }
    let(:pass_percentage) { 70 }
    let(:max_points) { 100.0 }

    context 'that has not been submitted' do
      let(:user_state) { 'visited' }

      it_behaves_like 'not marked as completed'
    end

    context 'below the pass percentage, even if above the usual warning threshold' do
      let(:user_points) { 65.0 }

      it_behaves_like 'not marked as completed'

      it { is_expected.to be_failed }
    end

    context 'at the pass percentage' do
      let(:user_points) { 70.0 }

      it_behaves_like 'marked as completed'

      it { is_expected.not_to be_failed }
    end

    context 'above the pass percentage' do
      let(:user_points) { 95.0 }

      it_behaves_like 'marked as completed'
    end

    context 'with a high pass percentage' do
      let(:pass_percentage) { 90 }

      context 'below it (but above the usual 95% completed threshold gap)' do
        let(:user_points) { 85.0 }

        it_behaves_like 'not marked as completed'
      end

      context 'at or above it' do
        let(:user_points) { 90.0 }

        it_behaves_like 'marked as completed'
      end
    end
  end

  context 'for a quiz other than an exam with a low score' do
    let(:user_points) { 1.0 }

    it { is_expected.not_to be_failed }
  end

  context 'for a survey' do
    let(:exercise_type) { 'survey' }

    context 'that has been visited only' do
      let(:user_state) { 'visited' }

      it_behaves_like 'not marked as completed'
    end

    context 'that has been submitted' do
      let(:user_state) { 'submitted' }

      it_behaves_like 'marked as completed'
    end
  end

  context 'for a non-gradable CMI5 item' do
    let(:content_type) { 'cmi5' }
    let(:exercise_type) { nil }
    let(:max_points) { nil }

    context 'that has not been visited' do
      let(:user_state) { 'new' }

      it_behaves_like 'not marked as completed'
    end

    context 'that has been visited' do
      let(:user_state) { 'visited' }

      it_behaves_like 'marked as completed'
    end
  end

  context 'for any other item' do
    let(:content_type) { 'video' }
    let(:exercise_type) { nil }
    let(:max_points) { nil }

    context 'that has not been visited' do
      let(:user_state) { 'new' }

      it_behaves_like 'not marked as completed'
    end

    context 'that has been visited' do
      let(:user_state) { 'visited' }

      it_behaves_like 'marked as completed'
    end
  end
end
