# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Course, type: :model do
  subject(:course) { create(:'course_service/course', :with_sections) }

  before { create(:'course_service/cluster', id: 'category') }

  it { is_expected.not_to accept_values_for(:title, '') }
  it { is_expected.to accept_values_for(:title, 'In-Memory Database Management', 'Internetworking mit TCP/IP', 'Semantic Web Technologies') }

  it { is_expected.to accept_values_for(:placement, [], ['Archive'], ['Open4All'], %w[Archive Open4All]) }
  it { is_expected.not_to accept_values_for(:placement, nil, ['Active'], %w[Archive Active], %w[Open4All Open4All]) }

  it { is_expected.not_to accept_values_for(:course_code, '', 'ab cd', 'a%$/a', 'a/b', 'a`b', 'a\'b') }
  it { is_expected.to accept_values_for(:course_code, 'course', '1234', 'my-course') }

  it 'does not allow duplicate course codes (case-insensitive)' do
    create(:'course_service/course', course_code: 'The-Course')

    expect do
      create(:'course_service/course', course_code: 'the-course')
    end.to raise_error(ActiveRecord::RecordInvalid, /Course code has already been taken/)
  end

  it 'does not allow a start_date being later than the end date' do
    expect do
      create(:'course_service/course', start_date: Time.zone.now, end_date: 7.days.ago)
    end.to raise_error(ActiveRecord::RecordInvalid, /The start date cannot be later than the end date/)
  end

  # Tip: Recreate the classifier object here, otherwise you will see type mismatch errors.
  it { is_expected.to accept_values_for(:classifiers, {}, {category: ['somecat']}, create(:'course_service/classifier')) }

  it 'creates a classifier with title and translations' do
    course = create(:'course_service/course')
    course.update!(classifiers: {category: ['somecat']})
    expect(course.classifiers).to contain_exactly(an_object_having_attributes(title: 'somecat', translations: {'en' => 'somecat'}))
  end

  it 'allows creating a course not assigned to a channel' do
    expect(course.channels).to be_empty
  end

  it 'allows assigning a course to a channel' do
    course = create(:'course_service/course', :with_channel)
    expect(course.channels).to all(be_a(CourseService::Channel))
  end

  it { is_expected.to accept_values_for(:cop_threshold_percentage, 1, 42, 100, nil) }
  it { is_expected.not_to accept_values_for(:cop_threshold_percentage, -42, 0, 101, 200, 50.5, 'hello') }

  it { is_expected.to accept_values_for(:roa_threshold_percentage, 1, 42, 100, nil) }
  it { is_expected.not_to accept_values_for(:roa_threshold_percentage, -42, 0, 101, 200, 50.5, 'hello') }

  it { is_expected.to accept_values_for(:learning_goals, %w[an array of strings]) }

  it 'has sections' do
    expect(course.sections.size).to eq 3
  end

  it 'has zero as a enrollment delta default' do
    expect(course.enrollment_delta).to eq 0
  end

  context '(date and search update jobs)' do
    subject(:course) { build(:'course_service/course') }

    it 'enqueues sync jobs for newly created course' do
      expect { course.save }
        .to have_enqueued_job(CourseService::NextDate::CourseStartSyncJob)
        .and have_enqueued_job(CourseService::UpdateCourseSearchIndexJob)
    end

    it 'publishes an event for updated course' do
      course.save
      course.title = 'New awesome Company1 Course'

      expect { course.save }
        .to have_enqueued_job(PinboardService::SearchCourseUpdateJob)
        .with(hash_including('title' => 'New awesome Company1 Course'))
    end

    it 'updates pinboard search index for deleted course' do
      course.save
      course.deleted = true

      expect { course.save }
        .to have_enqueued_job(PinboardService::SearchCourseUpdateJob)
        .with(kind_of(Hash))
    end
  end

  context 'with items' do
    let(:section) { create(:'course_service/section', course:) }
    let!(:items) { create_list(:'course_service/item', 5, section:) }

    its(:items) { is_expected.to eq items }
  end

  context 'with homeworks' do
    let(:section) { create(:'course_service/section', course:) }
    let!(:homeworks) { create_list(:'course_service/item', 5, :homework, section:) }

    its('items.homeworks') { is_expected.to eq homeworks }
  end

  context 'custom middle date is not set' do
    date = Time.zone.today
    subject(:course) { create(:'course_service/course', start_date: date - 3.days, end_date: date - 1.day, middle_of_course: nil) }

    it 'has a correct course middle' do
      expect(course.middle_of_course).to eq date - 2.days
      expect(course.middle_of_course_is_auto?).to be true
    end
  end

  context 'custom middle date is set' do
    date = Time.zone.today
    subject(:course) { create(:'course_service/course', start_date: date - 5.days, end_date: date - 1.day, middle_of_course: date - 3.days) }

    it 'has a correct course middle' do
      expect(course.middle_of_course).to eq date - 3.days
      expect(course.middle_of_course_is_auto?).to be false
    end
  end

  context 'published?' do
    subject(:course) { create(:'course_service/course', published: true, start_date: 2.days.ago, end_date: 1.day.ago) }

    it 'returns the persisted published value regardless of course end date' do
      expect(course.published).to be true

      course.end_date = 1.day.from_now
      course.save

      expect(course.published).to be true
    end
  end

  context 'scopes' do
    describe '#by_identifier' do
      subject { CourseService::Course.by_identifier(identifier).take! }

      let!(:uuid_course) { create(:'course_service/course') }
      let!(:slug_course) { create(:'course_service/course', course_code: 'javaeinstieg2015') }

      context 'with UUID' do
        let(:identifier) { uuid_course.id }

        it { is_expected.to eq uuid_course }
      end

      context 'with a course code' do
        let(:identifier) { 'javaeinstieg2015' }

        it { is_expected.to eq slug_course }
      end
    end

    describe 'current' do
      subject { CourseService::Course.current.pluck :id }

      before do
        # And two courses that are not current (one ended, one not started yet)
        create(:'course_service/course', :active, start_date: 1.week.from_now)
        create(:'course_service/course', :self_paced)
      end

      let!(:course_active) { create(:'course_service/course', :active) }

      it { is_expected.to eq [course_active.id] }
    end

    describe 'self_paced' do
      subject { CourseService::Course.self_paced.pluck :id }

      before do
        create(:'course_service/course')
        create(:'course_service/course', :active)
      end

      let!(:self_paced) { create(:'course_service/course', :self_paced) }

      it { is_expected.to eq [self_paced.id] }
    end

    describe 'in_preparation' do
      subject { CourseService::Course.in_preparation.pluck :id }

      before do
        create(:'course_service/course', :active)
        create(:'course_service/course', :self_paced)
      end

      let!(:in_prep) { create(:'course_service/course', published: false) }

      it { is_expected.to eq [in_prep.id] }
    end

    describe 'visible' do
      subject { CourseService::Course.visible.pluck :id }

      before { create(:'course_service/course', placement: []) }

      let!(:visible) { create(:'course_service/course') }

      it { is_expected.to eq [visible.id] }
    end

    describe 'deleted_for_purge' do
      subject { CourseService::Course.deleted_for_purge.pluck :id }

      let(:deleted_for_purge) { create(:'course_service/course', skip_account_groups: true, deleted: true, deleted_at: 7.months.ago) }

      before do
        deleted_for_purge
        create(:'course_service/course', skip_account_groups: true, deleted: true, deleted_at: 5.months.ago)
        create(:'course_service/course', skip_account_groups: true)
      end

      it { is_expected.to eq [deleted_for_purge.id] }
    end

    describe 'not_started' do
      subject { CourseService::Course.not_started.pluck :id }

      before { create(:'course_service/course', :active) }

      let!(:no_start_date) { create(:'course_service/course', start_date: nil) }
      let!(:future_start)  { create(:'course_service/course', :upcoming) }

      it { is_expected.to contain_exactly(no_start_date.id, future_start.id) }
    end

    describe 'ended' do
      subject { CourseService::Course.ended.pluck :id }

      before do
        create(:'course_service/course', :active)
        create(:'course_service/course', end_date: nil)
      end

      let!(:ended) { create(:'course_service/course', start_date: 4.weeks.ago, end_date: 1.week.ago) }

      it { is_expected.to eq [ended.id] }
    end
  end

  describe '#started?' do
    subject { course.started? }

    context 'for an active course' do
      let(:course) { create(:'course_service/course', :active) }

      it { is_expected.to be true }
    end

    context 'for an self-paced course' do
      let(:course) { create(:'course_service/course', :self_paced) }

      it { is_expected.to be true }
    end

    context 'for a course without end date (self-paced)' do
      let(:course) { create(:'course_service/course', end_date: nil) }

      it { is_expected.to be true }
    end

    context 'for a course that has not yet started' do
      let(:course) { create(:'course_service/course', :upcoming) }

      it { is_expected.to be false }
    end
  end

  describe '#enrollable?' do
    subject { course.enrollable? }

    it { is_expected.to be true }

    context 'for an external course' do
      let(:course) { create(:'course_service/course', :external) }

      it { is_expected.to be false }
    end

    context 'for an invite-only course' do
      let(:course) { create(:'course_service/course', :invite_only) }

      it { is_expected.to be false }
    end
  end

  context 'enrollments' do
    before { create_list(:'course_service/enrollment', 5, course:) }

    it 'has enrollments' do
      expect(course.enrollments.size).to eq 5
    end

    context 'deleting the course' do
      subject(:deletion) do
        course.deleted = true
        course.save
        course.reload
      end

      it 'deletes enrollments' do
        expect { deletion }.to change { course.enrollments.map(&:deleted) }.from(Array.new(5, false)).to(Array.new(5, true))
      end
    end
  end

  context 'status' do
    subject { course.status }

    context 'for a course in preparation' do
      let(:course) { create(:'course_service/course', published: false) }

      it { is_expected.to eq 'preparation' }
    end

    context 'for an active course' do
      # published: true and start_date in the past and end_date in the future
      let(:course) { create(:'course_service/course', :active) }

      it { is_expected.to eq 'active' }
    end

    context 'for a self-paced course' do
      # published: true and (start_date in the past and end_date in the past) or (start_date in the past and end_date is nil)
      let(:course) { create(:'course_service/course', :self_paced) }

      it { is_expected.to eq 'self-paced' }
    end

    context 'for an upcoming course' do
      # published: true and start_date in the future
      let(:course) { create(:'course_service/course', :upcoming) }

      it { is_expected.to eq 'upcoming' }
    end

    context 'for a course with an external URL' do
      let(:course) { create(:'course_service/course', external_course_url: 'https://example.com') }

      it { is_expected.to eq 'external' }
    end
  end

  describe 'alternative teacher text' do
    subject { course.alternative_teacher_text }

    context 'nil' do
      let(:course) { create(:'course_service/course', alternative_teacher_text: nil) }

      it { is_expected.to be_nil }
    end

    context 'empty string' do
      let(:course) { create(:'course_service/course', alternative_teacher_text: '') }

      it { is_expected.to be_nil }
    end

    context 'only whitespaces' do
      let(:course) { create(:'course_service/course', alternative_teacher_text: '     ') }

      it { is_expected.to be_nil }
    end

    context 'real text' do
      let(:course) { create(:'course_service/course', alternative_teacher_text: 'Dr. Foo Bar') }

      it { is_expected.to eq 'Dr. Foo Bar' }
    end

    context 'cleared by update' do
      let(:course) { create(:'course_service/course', alternative_teacher_text: 'Dr. Foo Bar') }

      it do
        expect(course.alternative_teacher_text).to eq 'Dr. Foo Bar'
        course.alternative_teacher_text = ''
        expect(course.alternative_teacher_text).to be_nil
      end
    end
  end

  describe '#public?' do
    subject { course.public? }

    let(:attributes) { {published: true} }
    let(:course) { create(:'course_service/course', attributes) }

    it { is_expected.to be true }

    context 'with course in preparation' do
      let(:attributes) { {published: false} }

      it { is_expected.to be false }
    end

    context 'with hidden course' do
      let(:attributes) { super().merge(placement: []) }

      it { is_expected.to be false }
    end

    context 'with group restriction' do
      let(:attributes) { super().merge(groups: ['partners']) }

      it { is_expected.to be false }
    end
  end

  describe 'certificates' do
    let!(:course) do
      create(:'course_service/course',
        records_released:,
        roa_enabled:,
        cop_enabled:,
        roa_threshold_percentage:,
        cop_threshold_percentage:)
    end
    let(:user) { create(:'account_service/user') }
    let(:user_id) { user.id }
    let!(:enrollment) { create(:'course_service/enrollment', :with_evaluation, course:, user_id:) }
    let(:records_released) { false }
    let(:roa_enabled) { false }
    let(:cop_enabled) { false }
    let(:roa_threshold_percentage) { nil }
    let(:cop_threshold_percentage) { nil }

    before do
      Xikolo.config.roa_threshold_percentage = 50
      Xikolo.config.cop_threshold_percentage = 50
    end

    describe 'record_of_achievement?' do
      subject { course.record_of_achievement? enrollment }

      context 'with not released records' do
        let(:roa_enabled) { true }

        it { is_expected.to be false }
      end

      context 'with not enabled roa' do
        let(:records_released) { true }

        it { is_expected.to be false }
      end

      context 'with released records and roa enabled' do
        let(:records_released) { true }
        let(:roa_enabled) { true }
        let(:points_percentage) { 42 }

        before do
          allow(enrollment).to receive(:points_percentage).and_return points_percentage
        end

        context 'not reached points for roa' do
          it { is_expected.to be false }
        end

        context 'not reached points for roa (global threshold to high)' do
          before do
            Xikolo.config.roa_threshold_percentage = 60
          end

          it { is_expected.to be false }
        end

        context 'not reached points for roa (course threshold to high)' do
          let(:roa_threshold_percentage) { 60 }

          it { is_expected.to be false }
        end

        context 'reached points for roa (course threshold overwrites global threshold)' do
          before do
            Xikolo.config.roa_threshold_percentage = 60
          end

          let(:roa_threshold_percentage) { 50 }
          let(:points_percentage) { 55 }

          it { is_expected.to be true }
        end

        context 'reached points for roa' do
          let(:points_percentage) { 50 }

          it { is_expected.to be true }
        end
      end

      context 'when the course has an exam' do
        let(:records_released) { true }
        let(:roa_enabled) { true }
        let(:section) { create(:'course_service/section', course:) }
        let(:exam_quiz) { create(:'quiz_service/quiz', :with_valid_question_pool) }
        let(:exam) do
          create(:'course_service/item', :quiz, exercise_type: 'exam',
            section:, content: exam_quiz)
        end

        def create_exam_submission(learner_id:, question_points:, submission_points:)
          question = create(:'quiz_service/multiple_choice_question', quiz: exam_quiz, points: question_points)
          create(:'quiz_service/quiz_submission', quiz: exam_quiz, user_id: learner_id,
            quiz_submission_time: 1.hour.ago).tap do |submission|
            create(:'quiz_service/quiz_submission_question',
              quiz_submission: submission, quiz_question_id: question.id, points: submission_points)
          end
        end

        before { exam }

        context 'without a submitted exam attempt' do
          it { is_expected.to be false }
        end

        context 'with an unsubmitted exam attempt' do
          before do
            create(:'quiz_service/quiz_submission', quiz: exam_quiz, user_id:)
          end

          it { is_expected.to be false }
        end

        context 'with a submitted exam attempt below the passing threshold' do
          before { create_exam_submission(learner_id: user_id, question_points: 10, submission_points: 4) }

          it { is_expected.to be false }
        end

        context 'with a submitted exam attempt reaching the passing threshold' do
          before { create_exam_submission(learner_id: user_id, question_points: 10, submission_points: 7) }

          it { is_expected.to be true }
        end

        context 'with a passing exam attempt by another user' do
          let(:other_user_id) { create(:'account_service/user').id }

          before { create_exam_submission(learner_id: other_user_id, question_points: 10, submission_points: 7) }

          it { is_expected.to be false }
        end
      end
    end

    describe 'confirmation_of_participation?' do
      subject { course.confirmation_of_participation? enrollment }

      context 'with not released records' do
        let(:cop_enabled) { true }

        it { is_expected.to be false }
      end

      context 'with not enabled cop' do
        let(:records_released) { true }

        it { is_expected.to be false }
      end

      context 'with released records and cop enabled' do
        let(:records_released) { true }
        let(:cop_enabled) { true }

        # TODO: Test should test implemented methods.
        around do |examples|
          RSpec::Mocks.configuration.verify_partial_doubles = false
          examples.run
          RSpec::Mocks.configuration.verify_partial_doubles = true
        end

        before { allow(enrollment).to receive(:visits_percentage).and_return visits_percentage }

        context 'not enough items visited' do
          let(:visits_percentage) { 49 }

          context 'not enabled roa' do
            let(:roa_enabled) { false }

            it { is_expected.to be false }
          end

          context 'enabled roa' do
            let(:roa_enabled) { true }
            let(:points_percentage) { 42 }

            before do
              allow(enrollment).to receive(:points_percentage).and_return points_percentage
            end

            context 'not reached points for roa' do
              it { is_expected.to be false }
            end

            context 'not reached points for roa (global threshold to high)' do
              before do
                Xikolo.config.roa_threshold_percentage = 60
              end

              it { is_expected.to be false }
            end

            context 'not reached points for roa (course threshold to high)' do
              let(:roa_threshold_percentage) { 60 }

              it { is_expected.to be false }
            end

            context 'reached points for roa (course threshold overwrites global threshold)' do
              before do
                Xikolo.config.roa_threshold_percentage = 60
              end

              let(:roa_threshold_percentage) { 50 }
              let(:points_percentage) { 55 }

              it { is_expected.to be true }
            end

            context 'reached points for roa' do
              let(:points_percentage) { 50 }

              it { is_expected.to be true }
            end
          end
        end

        context 'not enough items visited (global threshold to high)' do
          before do
            Xikolo.config.cop_threshold_percentage = 60
          end

          let(:visits_percentage) { 50 }

          it { is_expected.to be false }
        end

        context 'not enough items visited (course threshold to high)' do
          let(:cop_threshold_percentage) { 60 }
          let(:visits_percentage) { 50 }

          it { is_expected.to be false }
        end

        context 'enough items visited (course threshold overwrites global threshold)' do
          before do
            Xikolo.config.cop_threshold_percentage = 60
          end

          let(:cop_threshold_percentage) { 50 }
          let(:visits_percentage) { 50 }

          it { is_expected.to be true }
        end

        context 'enough items visited' do
          let(:visits_percentage) { 50 }

          it { is_expected.to be true }
        end
      end
    end

    describe 'certificate?' do
      subject { course.certificate? enrollment }

      context 'with not released records' do
        let(:roa_enabled) { true }

        it { is_expected.to be false }
      end

      context 'with released records' do
        let(:records_released) { true }
        let(:roa_enabled) { true }

        context 'without an issued certificate' do
          it { is_expected.to be false }
        end

        context 'with an issued certificate' do
          before { create(:certificate, user:, course:) }

          it { is_expected.to be true }
        end
      end
    end
  end
end
