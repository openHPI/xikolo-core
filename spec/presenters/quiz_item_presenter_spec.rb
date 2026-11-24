# frozen_string_literal: true

require 'spec_helper'

describe QuizItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item: item_resource, course: course, user:, quiz: quiz_resource,
      enrollment: CourseService::Enrollment.new(enrollment.attributes)
  end

  let(:course) { create(:course, :active, course_code: 'test') }
  let(:quiz) { create(:'quiz_service/quiz', id: quiz_params[:id]) }
  let(:item) { create(:item, content: quiz, exercise_type: 'selftest') }
  let(:item_resource) do
    build(:'course:item', id: item.id, content_type: item.content_type, content_id: item.content_id, **additional_item_params)
  end
  let(:additional_item_params) { {} }
  let(:quiz_resource) { Xikolo::Quiz::Quiz.new quiz_params }
  let(:quiz_params) { {id: generate(:quiz_id), current_allowed_attempts: 1} }

  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:user_id) { session.user.id }
  let(:enrollment) { create(:enrollment, course:, user_id:) }

  before do
    role = create(:'account_service/role', permissions: %w[course.content.access.available])
    create(:'account_service/grant', principal: session.user, role:)
  end

  describe '#instruction_action' do
    subject(:action) { presenter.instruction_action }

    let(:presenter) do
      described_class.new(item: item_resource, course:, user:, quiz: quiz_resource, submission:, attempts:)
    end
    let(:additional_item_params) { {exercise_type: 'main'} }
    let(:quiz_params) { super().merge(current_allowed_attempts: 2) }
    let(:submission) { nil }
    let(:attempts) { Xikolo::Submission::UserQuizAttempts.new(attempts: 1, additional_attempts: 0) }

    it { is_expected.to eq(:start_quiz) }

    context 'with an exam' do
      let(:additional_item_params) { {exercise_type: 'exam', minimum_progress_percentage: 75} }

      it { is_expected.to eq(:locked) }

      context 'with progress below the threshold' do
        before do
          create(:'course_service/course_progress', course:, user_id:, visits_percentage_fpoints: 7499)
        end

        it { is_expected.to eq(:locked) }
      end

      context 'with progress at the threshold' do
        before do
          create(:'course_service/course_progress', course:, user_id:, visits_percentage_fpoints: 7500)
        end

        it { is_expected.to eq(:start_exam) }

        context 'when the exam has been passed' do
          let(:submission) { Xikolo::Submission::QuizSubmission.new(submitted: true, points: 70, max_points: 100) }

          it { is_expected.to be_nil }
        end
      end
    end

    context 'with a previous submission' do
      let(:submission) { Xikolo::Submission::QuizSubmission.new(submitted: true) }

      it { is_expected.to eq(:retake_with_results) }

      context 'before results are published' do
        let(:additional_item_params) do
          super().merge(submission_deadline: 2.days.from_now.iso8601(3),
            submission_publishing_date: 3.days.from_now.iso8601(3))
        end

        it { is_expected.to eq(:retake) }
      end

      context 'without attempts left' do
        let(:attempts) { Xikolo::Submission::UserQuizAttempts.new(attempts: 2, additional_attempts: 0) }

        it { is_expected.to be_nil }
      end
    end
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

      it { is_expected.to eq 'learning_material' }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.to eq 'learning_material' }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.to eq 'learning_material' }
    end

    context "when the exercise_type is 'exam'" do
      let(:additional_item_params) { {exercise_type: 'exam'} }

      it { is_expected.to eq 'exam' }
    end

    context "when the exercise_type is 'survey'" do
      let(:additional_item_params) { {exercise_type: 'survey'} }

      it { is_expected.to eq 'survey' }
    end

    context 'without an exercise_type' do
      it { is_expected.to eq 'learning_material' }
    end
  end

  describe '#quiz_submittable?' do
    subject { presenter.quiz_submittable? }

    it { is_expected.to be true }
  end

  describe '#user_instrumented?' do
    subject { presenter.send(:user_instrumented?) }

    context 'when the user is not instrumented' do
      it { is_expected.to be false }
    end

    context 'with an instrumented user' do
      before do
        session.masquerade!(create(:'account_service/user'))
      end

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

  describe '#quiz_results_published?' do
    subject { presenter.send(:quiz_results_published?) }

    context 'without a submission_publishing_date' do
      it { is_expected.to be false }
    end

    context 'with a submission_publishing_date in the future' do
      let(:additional_item_params) { {submission_publishing_date: 2.days.from_now.iso8601(3)} }

      it { is_expected.to be false }
    end

    context 'with a submission_publishing_date in the past' do
      let(:additional_item_params) { {submission_publishing_date: 2.days.ago.iso8601(3)} }

      it { is_expected.to be true }
    end
  end
end
