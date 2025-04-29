# frozen_string_literal: true

require 'spec_helper'

describe QuizItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item: item_resource, course: course_resource, user:, quiz: quiz_resource,
      enrollment: Xikolo::Course::Enrollment.new(enrollment.attributes)
  end

  let(:course) { create(:course, :active, :offers_proctoring, course_code: 'test') }
  let(:course_resource) { Xikolo::Course::Course.new(id: course.id, course_code: course.course_code) }
  let(:item) { create(:item, content_type: 'quiz', content_id: quiz_resource.id) }
  let(:item_resource) do
    Xikolo::Course::Item.new(id: item.id, content_type: item.content_type, content_id: item.content_id, **additional_item_params)
  end
  let(:additional_item_params) { {} }
  let(:quiz_resource) { Xikolo::Quiz::Quiz.new quiz_params }
  let(:quiz_params) { {id: generate(:quiz_id), current_allowed_attempts: 1} }

  let(:features) { {} }
  let(:masqueraded) { false }
  let(:user_id) { generate(:user_id) }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => %w[course.content.access.available],
      'features' => features,
      'masqueraded' => masqueraded,
      'user' => {'anonymous' => false}
    )
  end
  let(:proctoring_context) { instance_double(Proctoring::ItemContext) }
  let(:enrollment) { create(:enrollment, :proctored, course:, user_id:) }

  before do
    allow(Proctoring::ItemContext).to receive(:new).and_return(proctoring_context)
  end

  describe '#survey?' do
    context 'without an exercise_type' do
      let(:additional_item_params) { {exercise_type: nil} }

      it { is_expected.to be_survey }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.not_to be_survey }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.not_to be_survey }
    end
  end

  describe '#graded?' do
    context 'without an exercise_type' do
      let(:additional_item_params) { {exercise_type: nil} }

      it { is_expected.not_to be_graded }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.to be_graded }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.to be_graded }
    end
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    context "when the exercise_type is 'selftest'" do
      let(:additional_item_params) { {exercise_type: 'selftest'} }

      it { is_expected.to eq 'lightbulb-on' }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.to eq 'money-check-pen' }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.to eq 'lightbulb-on+circle-star' }
    end

    context 'without an exercise_type' do
      it { is_expected.to eq 'clipboard-list-check' }
    end
  end

  describe '#quiz_submittable?' do
    subject { presenter.quiz_submittable? }

    context 'with the proctoring feature being disabled' do
      it { is_expected.to be true }
    end

    context 'with the proctoring feature being enabled' do
      let(:features) { {'proctoring' => true} }

      context 'when the user is instrumented' do
        let(:masqueraded) { true }

        before do
          allow(proctoring_context).to receive(:enabled?).and_return(false)
        end

        it { is_expected.to be true }
      end

      context 'when the proctoring context for the item is disabled' do
        # ItemContext not configured, enrollment not proctored, ...
        before do
          allow(proctoring_context).to receive(:enabled?).and_return(false)
        end

        it { is_expected.to be true }
      end

      context 'when the proctoring context for the item is enabled' do
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

    context 'when the user is not instrumented' do
      it { is_expected.to be false }
    end

    context 'with an instrumented user' do
      let(:masqueraded) { true }

      it { is_expected.to be true }
    end
  end

  describe '#basic_quiz_properties' do
    subject(:quiz_properties) { presenter.send(:basic_quiz_properties) }

    let(:item_params) { super().merge content_type: quiz.id }

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it 'has the homework property' do
        expect(quiz_properties).to include(name: 'homework', icon_class: 'money-check-pen')
      end
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it 'has the bonus property' do
        expect(quiz_properties).to include(name: 'bonus', icon_class: 'lightbulb-on+circle-star')
      end
    end

    context "when the exercise_type is 'selftest'" do
      let(:additional_item_params) { {exercise_type: 'selftest'} }

      it 'has the selftest property' do
        expect(quiz_properties).to include(name: 'selftest', icon_class: 'lightbulb-on')
      end
    end

    context 'with unlimited time' do
      let(:quiz_params) { super().merge current_unlimited_time: true }

      it 'has unlimited time' do
        expect(quiz_properties).to include(name: 'unlimited_time', icon_class: 'timer')
      end
    end

    context 'with a time limit' do
      let(:quiz_params) { super().merge current_time_limit_seconds: 60 }

      it 'has 1 minute time limit' do
        expect(quiz_properties).to include(name: 'time_limit', icon_class: 'timer', opts: {limit: 1})
      end
    end

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
