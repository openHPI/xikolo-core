# frozen_string_literal: true

require 'spec_helper'

describe Course, type: :model do
  subject(:course) { create(:course, :with_sections) }

  before { create(:cluster, id: 'category') }

  it { is_expected.not_to accept_values_for(:title, '') }
  it { is_expected.to accept_values_for(:title, 'In-Memory Database Management', 'Internetworking mit TCP/IP', 'Semantic Web Technologies') }

  it { is_expected.to accept_values_for(:status, 'preparation', 'active', 'archive') }
  it { is_expected.not_to accept_values_for(:status, 'preparing', 'Vorschau', 'Preview', 'preview', 'Archive') }

  it { is_expected.not_to accept_values_for(:course_code, '', 'ab cd', 'a%$/a', 'a/b', 'a`b', 'a\'b') }
  it { is_expected.to accept_values_for(:course_code, 'course', '1234', 'my-course') }

  it 'does not allow duplicate course codes (case-insensitive)' do
    create(:course, course_code: 'The-Course')

    expect do
      create(:course, course_code: 'the-course')
    end.to raise_error(ActiveRecord::RecordInvalid, /Course code has already been taken/)
  end

  # Tip: Recreate the classifier object here, otherwise you will see type mismatch errors.
  it { is_expected.to accept_values_for(:classifiers, {}, {category: ['somecat']}, create(:classifier)) }

  it 'creates a classifier with title and translations' do
    course = create(:course)
    course.update!(classifiers: {category: ['somecat']})
    expect(course.classifiers).to contain_exactly(an_object_having_attributes(title: 'somecat', translations: {'en' => 'somecat'}))
  end

  it 'allows creating a course not assigned to a channel' do
    expect(course.channel).to be_nil
  end

  it 'allows assigning a course to a channel' do
    course = create(:course, :with_channel)
    expect(course.channel).to be_a Channel
  end

  it { is_expected.to accept_values_for(:cop_threshold_percentage, 1, 42, 100, nil) }
  it { is_expected.not_to accept_values_for(:cop_threshold_percentage, -42, 0, 101, 200, 50.5, 'hello') }

  it { is_expected.to accept_values_for(:roa_threshold_percentage, 1, 42, 100, nil) }
  it { is_expected.not_to accept_values_for(:roa_threshold_percentage, -42, 0, 101, 200, 50.5, 'hello') }

  it { is_expected.to accept_values_for(:learning_goals, %w[an array of strings]) }

  it { is_expected.to accept_values_for(:target_groups, %w[an array of strings]) }

  it 'has sections' do
    expect(course.sections.size).to eq 3
  end

  it 'has zero as a enrollment delta default' do
    expect(course.enrollment_delta).to eq 0
  end

  context '(event publication)' do
    subject(:course) { build(:course) }

    it 'publishes an event for newly created course' do
      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.course.create'))
      course.save
    end

    it 'publishes an event for updated course' do
      course.save

      expect(Msgr).to receive(:publish) do |updated_course_as_hash, msgr_params|
        expect(updated_course_as_hash).to be_a(Hash)
        expect(updated_course_as_hash).to include('title' => 'New awesome Company1 Course')
        expect(msgr_params).to include(to: 'xikolo.course.course.update')
      end

      course.title = 'New awesome Company1 Course'
      course.save
    end

    it 'publishes events for deleted course' do
      course.save

      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.course.update'))
      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.course.destroy'))

      course.deleted = true
      course.save
    end
  end

  context '(enrollment completion worker)' do
    subject(:course) { create(:course, records_released:) }

    let(:records_released) { false }

    it 'starts one worker when records_released enabled' do
      expect do
        course.records_released = true
        course.save
      end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
    end

    it 'starts only one worker when records_released enabled and thresholds change' do
      expect do
        course.records_released = true
        course.roa_threshold_percentage = 50
        course.cop_threshold_percentage = 50
        course.save
      end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
    end

    it 'does not start worker when records_released disabled and thresholds change' do
      expect do
        course.roa_threshold_percentage = 50
        course.cop_threshold_percentage = 50
        course.save
      end.not_to change(EnrollmentCompletionWorker.jobs, :size)
    end

    context 'records_released already enabled and thresholds change' do
      let(:records_released) { true }

      it 'starts one worker when roa threshold change' do
        expect do
          course.roa_threshold_percentage = 50
          course.save
        end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
      end

      it 'starts one worker when cop threshold change' do
        expect do
          course.cop_threshold_percentage = 50
          course.save
        end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
      end

      it 'starts only one worker when both thresholds change' do
        expect do
          course.roa_threshold_percentage = 50
          course.cop_threshold_percentage = 50
          course.save
        end.to change(EnrollmentCompletionWorker.jobs, :size).from(0).to(1)
      end
    end
  end

  context 'with items' do
    let(:section) { create(:section, course:) }
    let!(:items) { create_list(:item, 5, section:) }

    its(:items) { is_expected.to eq items }
  end

  context 'with homeworks' do
    let(:section) { create(:section, course:) }
    let!(:homeworks) { create_list(:item, 5, :homework, section:) }

    its('items.homeworks') { is_expected.to eq homeworks }
  end

  context 'custom middle date is not set' do
    date = Time.zone.today
    subject(:course) { create(:course, start_date: date - 3.days, end_date: date - 1.day, middle_of_course: nil) }

    it 'has a correct course middle' do
      expect(course.middle_of_course).to eq date - 2.days
      expect(course.middle_of_course_is_auto?).to be true
    end
  end

  context 'custom middle date is set' do
    date = Time.zone.today
    subject(:course) { create(:course, start_date: date - 5.days, end_date: date - 1.day, middle_of_course: date - 3.days) }

    it 'has a correct course middle' do
      expect(course.middle_of_course).to eq date - 3.days
      expect(course.middle_of_course_is_auto?).to be false
    end
  end

  context 'change state of course' do
    subject(:course) { create(:course, auto_archive: true, status: 'active', start_date: 2.days.ago, end_date: 1.day.ago) }

    it 'auto-archives' do
      expect(course.auto_archive).to be true
    end

    it 'changes the course state based on the auto archive' do
      expect(course.status).to eq 'archive'
      course.auto_archive = false
      course.save
      expect(course.status).to eq 'active'
    end

    it 'does not change the course state of a running course' do
      course.end_date = 1.day.from_now
      course.save
      expect(course.status).to eq 'active'
    end
  end

  context 'scopes' do
    describe '#by_identifier' do
      subject { Course.by_identifier(identifier).take! }

      let!(:uuid_course) { create(:course) }
      let!(:slug_course) { create(:course, course_code: 'javaeinstieg2015') }

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
      subject { Course.current.pluck :id }

      before do
        course

        # And two already ended courses (one of which is still marked active)
        create(:course, :archived)
        create(:course, :archived, status: 'active')
      end

      let!(:course_active) { create(:course, :active) }

      it { is_expected.to eq [course_active.id] }
    end

    describe 'for_user' do
      subject(:courses) { Course.for_user(current_user) }

      let(:active_course) { create(:course, :active, attributes: {title: 'Active'}) }
      let(:preparation_course) { create(:course, attributes: {title: 'Preparation', status: 'preparation'}) }
      let(:hidden_course) { create(:course, attributes: {title: 'Hidden', status: 'active', hidden: true}) }
      let(:partner_course) { create(:course, attributes: {title: 'Partner', status: 'active', groups: ['partners']}) }

      let(:current_user) do
        Xikolo::Common::Auth::CurrentUser.from_session(
          'permissions' => permissions,
          'features' => {},
          'user' => {
            'anonymous' => false,
          },
          'user_id' => user_id
        )
      end

      let(:user_id) { SecureRandom.uuid }
      let(:permissions) { {} }
      let(:user_groups) { [] }

      before do
        Stub.service(
          :account,
          group_url: '/groups/{id}',
          groups_url: '/groups'
        )

        Stub.request(
          :account,
          :get,
          '/groups',
          query: {user: user_id, per_page: 1000}
        ).to_return Stub.json(user_groups)

        Stub.request(
          :account,
          :get,
          '/groups',
          query: {user: 'anonymous', per_page: 1000}
        ).to_return Stub.json([])
      end

      context 'as admin user' do
        let(:permissions) { ['course.course.index'] }

        it 'contains all courses' do
          expect(courses).to contain_exactly(active_course, preparation_course, hidden_course, partner_course)
        end
      end

      context 'as anonymous user' do
        let(:current_user) { Xikolo::Common::Auth::CurrentUser.from_session({}) }

        it 'contains the active course' do
          expect(courses).to contain_exactly(active_course)
        end
      end

      context 'as student user' do
        it 'contains the active course' do
          expect(courses).to contain_exactly(active_course)
        end

        context 'with partner group membership' do
          let(:user_groups) do
            [
              {name: 'partners'},
            ]
          end

          it 'contains active and partner course' do
            expect(courses).to contain_exactly(active_course, partner_course)
          end
        end

        context 'with enrollment' do
          context 'in hidden course' do
            before { create(:enrollment, course: hidden_course, user_id:) }

            it 'contains active and partner course' do
              expect(courses).to contain_exactly(active_course, hidden_course)
            end
          end

          context 'in group restricted course' do
            before { create(:enrollment, course: partner_course, user_id:) }

            it 'contains active and partner course' do
              expect(courses).to contain_exactly(active_course, partner_course)
            end
          end
        end
      end
    end
  end

  describe '#accessible?' do
    subject { course.accessible? }

    context 'for an active course' do
      let(:course) { create(:course, :active) }

      it { is_expected.to be true }
    end

    context 'for an archived course' do
      let(:course) { create(:course, :archived) }

      it { is_expected.to be true }
    end

    context 'for a course without end date (self-paced)' do
      let(:course) { create(:course, end_date: nil) }

      it { is_expected.to be true }
    end

    context 'for a course that has not yet started' do
      let(:course) { create(:course, :upcoming) }

      it { is_expected.to be false }
    end
  end

  describe '#enrollable?' do
    subject { course.enrollable? }

    it { is_expected.to be true }

    context 'for an external course' do
      let(:course) { create(:course, :external) }

      it { is_expected.to be false }
    end

    context 'for an invite-only course' do
      let(:course) { create(:course, :invite_only) }

      it { is_expected.to be false }
    end
  end

  context 'enrollments' do
    before { create_list(:enrollment, 5, course:) }

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

  describe 'alternative teacher text' do
    subject { course.alternative_teacher_text }

    context 'nil' do
      let(:course) { create(:course, alternative_teacher_text: nil) }

      it { is_expected.to be_nil }
    end

    context 'empty string' do
      let(:course) { create(:course, alternative_teacher_text: '') }

      it { is_expected.to be_nil }
    end

    context 'only whitespaces' do
      let(:course) { create(:course, alternative_teacher_text: '     ') }

      it { is_expected.to be_nil }
    end

    context 'real text' do
      let(:course) { create(:course, alternative_teacher_text: 'Dr. Foo Bar') }

      it { is_expected.to eq 'Dr. Foo Bar' }
    end

    context 'cleared by update' do
      let(:course) { create(:course, alternative_teacher_text: 'Dr. Foo Bar') }

      it do
        expect(course.alternative_teacher_text).to eq 'Dr. Foo Bar'
        course.alternative_teacher_text = ''
        expect(course.alternative_teacher_text).to be_nil
      end
    end
  end

  describe '#public?' do
    subject { course.public? }

    let(:attributes) { {status: 'active'} }
    let(:course) { create(:course, attributes) }

    it { is_expected.to be true }

    context 'with course in preparation' do
      let(:attributes) { {status: 'preparation'} }

      it { is_expected.to be false }
    end

    context 'with hidden course' do
      let(:attributes) { super().merge(hidden: true) }

      it { is_expected.to be false }
    end

    context 'with group restriction' do
      let(:attributes) { super().merge(groups: ['partners']) }

      it { is_expected.to be false }
    end
  end

  describe 'certificates' do
    let!(:course) do
      create(:course,
        records_released:,
        roa_enabled:,
        cop_enabled:,
        roa_threshold_percentage:,
        cop_threshold_percentage:)
    end
    let(:user_id) { SecureRandom.uuid }
    let!(:enrollment) { create(:enrollment, course:, user_id:, proctored: enrollment_proctored) }
    let(:records_released) { false }
    let(:enrollment_proctored) { false }
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

        context 'with not proctored enrollment' do
          it { is_expected.to be false }
        end

        context 'with proctored enrollment' do
          let(:enrollment_proctored) { true }

          context 'not enabled roa' do
            it { is_expected.to be false }
          end

          context 'enabled roa' do
            let(:roa_enabled) { true }
            let(:points_percentage) { 42 }

            before do
              allow(enrollment).to receive(:points_percentage).and_return points_percentage
            end

            context 'with roa not granted' do
              it { is_expected.to be false }
            end

            context 'with roa not granted and 6 dpoints' do
              let(:points_percentage) { 50 }

              it { is_expected.to be true }
            end
          end
        end
      end
    end

    describe '#transcript_of_records?' do
      subject(:transcript_of_records) { course.transcript_of_records? enrollment }

      it { is_expected.to be false }

      context 'with released records' do
        let(:records_released) { true }

        context 'without relations' do
          it { is_expected.to be false }
        end

        context 'with relation' do
          let(:required_course) { create(:course, :active, records_released: true, roa_enabled: true) }

          before do
            source = create(:course_set, courses: [course])
            target = create(:course_set, courses: [required_course])
            create(:course_set_relation, source_set: source, target_set: target, kind: 'requires_roa')
          end

          it { is_expected.to be false }

          context 'with enrollment in required course' do
            let(:homework_id) { SecureRandom.uuid }

            before do
              section = create(:section, course: required_course)
              create(:item, :homework, :with_max_points, id: homework_id, section:)
              create(:enrollment, course: required_course, user_id:)
            end

            it { is_expected.to be false }

            context '(fulfilled)' do
              before { create(:result, user_id:, item_id: homework_id, dpoints: 10) }

              it { is_expected.to be true }
            end
          end
        end
      end
    end
  end
end
