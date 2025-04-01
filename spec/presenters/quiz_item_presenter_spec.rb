# frozen_string_literal: true

require 'spec_helper'

describe QuizItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item:, course:, user:, quiz:,
      enrollment: Xikolo::Course::Enrollment.new(enrollment.attributes)
  end

  let(:item_id) { generate(:uuid) }
  let(:user_id) { generate(:user_id) }
  let(:item_params) { {id: item_id} }
  let(:item) { Xikolo::Course::Item.new item_params.merge content_type: 'quiz' }
  let(:course) { Xikolo::Course::Course.new id: generate(:course_id), course_code: 'test' }
  let(:features) { {} }
  let(:masqueraded) { false }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => %w[course.content.access.available],
      'features' => features,
      'masqueraded' => masqueraded,
      'user' => {'anonymous' => false}
    )
  end
  let(:quiz_params) { {id: generate(:quiz_id), current_allowed_attempts: 1} }
  let(:quiz) { Xikolo::Quiz::Quiz.new quiz_params }
  let(:proctoring_context) { instance_double(Proctoring::ItemContext) }
  let(:enrollment) do
    db_course = create(:course, :active, :offers_proctoring, id: course.id, course_code: 'test')
    create(:enrollment, :proctored, course: db_course, user_id:)
  end

  before do
    allow(Proctoring::ItemContext).to receive(:new).and_return(proctoring_context)
  end

  describe '#survey?' do
    context 'with exercise_type nil' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.to be_survey }
    end

    context 'with exercise_type main' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.not_to be_survey }
    end

    context 'with exercise_type bonus' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.not_to be_survey }
    end
  end

  describe '#graded?' do
    context 'with exercise_type nil' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.not_to be_graded }
    end

    context 'with exercise_type main' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to be_graded }
    end

    context 'with exercise_type bonus' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to be_graded }
    end
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    context 'as self-test' do
      let(:item_params) { super().merge exercise_type: 'selftest' }

      it { is_expected.to eq 'lightbulb-on' }
    end

    context 'as main exercise' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to eq 'money-check-pen' }
    end

    context 'as bonus exercise' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to eq 'lightbulb-on+circle-star' }
    end

    context 'without exercise' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.to eq 'clipboard-list-check' }
    end
  end

  describe '#quiz_submittable?' do
    subject { presenter.quiz_submittable? }

    context 'with disabled proctoring feature' do
      it { is_expected.to be true }
    end

    context 'with enabled proctoring feature' do
      let(:features) { {'proctoring' => true} }

      context 'user instrumented' do
        let(:masqueraded) { true }

        before do
          allow(proctoring_context).to receive(:enabled?).and_return(false)
        end

        it { is_expected.to be true }
      end

      context 'with proctoring (item) context disabled (not configured, enrollment not proctored, ...)' do
        before do
          allow(proctoring_context).to receive(:enabled?).and_return(false)
        end

        it { is_expected.to be true }
      end

      context 'with proctoring (item) context enabled' do
        before do
          allow(proctoring_context).to receive(:enabled?).and_return(true)
        end

        context 'with proctoring service unavailable' do
          it { is_expected.to be false }
        end
      end
    end
  end

  describe '#user_instrumented?' do
    subject { presenter.send(:user_instrumented?) }

    context 'with not instrumented user' do
      it { is_expected.to be false }
    end

    context 'with instrumented user' do
      let(:masqueraded) { true }

      it { is_expected.to be true }
    end
  end

  describe 'basic_quiz_properties' do
    subject(:quiz_properties) { presenter.send(:basic_quiz_properties) }

    let(:item_params) { super().merge content_type: quiz.id }

    context 'exercise type' do
      context 'main exercise' do
        let(:item_params) { super().merge exercise_type: 'main' }

        it 'has the homework property' do
          expect(quiz_properties).to include(name: 'homework', icon_class: 'money-check-pen')
        end
      end

      context 'bonus exercise' do
        let(:item_params) { super().merge exercise_type: 'bonus' }

        it 'has the bonus property' do
          expect(quiz_properties).to include(name: 'bonus', icon_class: 'lightbulb-on+circle-star')
        end
      end

      context 'selftest' do
        let(:item_params) { super().merge exercise_type: 'selftest' }

        it 'has the selftest property' do
          expect(quiz_properties).to include(name: 'selftest', icon_class: 'lightbulb-on')
        end
      end
    end

    context 'time limit' do
      context 'with unlimited time' do
        let(:quiz_params) { super().merge current_unlimited_time: true }

        it 'has unlimited time' do
          expect(quiz_properties).to include(name: 'unlimited_time', icon_class: 'timer')
        end
      end

      context 'with time limit' do
        let(:quiz_params) { super().merge current_time_limit_seconds: 60 }

        it 'has 1 minute time limit' do
          expect(quiz_properties).to include(name: 'time_limit', icon_class: 'timer', opts: {limit: 1})
        end
      end
    end

    context 'attempts' do
      context 'with unlimited attempts' do
        let(:quiz_params) { super().merge current_unlimited_attempts: true }

        it 'has unlimited attempts' do
          expect(quiz_properties).to include(name: 'unlimited_attempts', icon_class: 'ban')
        end
      end

      context 'with limited attempts' do
        it 'has one attempt' do
          expect(quiz_properties).to include(name: 'allowed_attempts', icon_class: 'ban', opts: {count: 1})
        end
      end
    end
  end
end
