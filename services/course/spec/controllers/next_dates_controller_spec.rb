# frozen_string_literal: true

require 'spec_helper'

describe NextDatesController, type: :controller do
  subject { action; json }

  let(:user_id) { generate(:user_id) }
  let(:other_user_id) { generate(:user_id) }
  let(:json) { JSON.parse response.body }
  let(:params) { {user_id:} }
  let(:action) { get :index, params: }
  let(:default_params) { {format: 'json'} }

  let(:course_params) { {start_date: nil, status: course_status, end_date: nil} }
  let(:course_status) { 'active' }
  let(:section) { create(:section, {course:}.merge(section_params)) }
  let(:section_params) { {start_date: nil, end_date: nil} }
  let(:item) { create(:item, {section:}.merge(item_params)) }
  let(:item_params) { {} }

  around do |example|
    Sidekiq::Testing.inline!(&example)
  end

  shared_examples 'a date of' do |course|
    let(:required_course) { send course }
    its(:keys) { is_expected.to eq %w[course_id course_code course_title resource_type resource_id type title date] }
    its(['course_id']) { is_expected.to eq required_course.id }
    its(['course_code']) { is_expected.to eq required_course.course_code }
    its(['course_title']) { is_expected.to eq required_course.title }
  end

  describe "GET 'index'" do
    let(:course) { create(:course, course_params) }
    let(:enrollment) { create(:enrollment, course:, user_id:) }

    context 'type "on demand expires"' do
      let(:course_params) { {start_date: 1.day.ago, status: 'archive'} }
      let(:forced_submission_date) { 8.weeks.from_now }

      before { enrollment.update!(forced_submission_date:) }

      its(:size) { is_expected.to eq 1 }

      context 'date' do
        subject { super()[0] }

        it_behaves_like 'a date of', :course
        its(['resource_type']) { is_expected.to eq 'on_demand' }
        its(['resource_id']) { is_expected.to eq course.id }
        its(['title']) { is_expected.to eq course.title.to_s }
        its(['type']) { is_expected.to eq 'on_demand_expires' }
        its(['date']) { is_expected.to eq forced_submission_date.iso8601(3) }
      end
    end

    context 'event type "course start"' do
      before { course; enrollment }

      let(:course_params) { {start_date:, display_start_date:, status: course_status} }
      let(:display_start_date) { nil }

      context 'without start_date' do
        let(:start_date) { nil }

        its(:size) { is_expected.to eq 0 }

        context 'but passed display_date' do
          let(:display_start_date) { 1.day.ago }

          its(:size) { is_expected.to eq 0 }
        end

        context 'but future display_date' do
          let(:display_start_date) { 1.day.from_now }

          its(:size) { is_expected.to eq 1 }

          context 'date' do
            subject { super()[0] }

            it_behaves_like 'a date of', :course
            its(['resource_type']) { is_expected.to eq 'course' }
            its(['resource_id']) { is_expected.to eq course.id }
            its(['title']) { is_expected.to eq course.title.to_s }
            its(['type']) { is_expected.to eq 'course_start' }
            its(['date']) { is_expected.to eq display_start_date.iso8601(3) }
          end
        end
      end

      context 'with passed start_date' do
        let(:start_date) { 2.days.ago }

        its(:size) { is_expected.to eq 0 }

        context 'but passed display_date' do
          let(:display_start_date) { 1.day.ago }

          its(:size) { is_expected.to eq 0 }
        end

        context 'but future display_date' do
          let(:display_start_date) { 1.day.from_now }

          its(:size) { is_expected.to eq 1 }

          context 'date' do
            subject { super()[0] }

            it_behaves_like 'a date of', :course
            its(['resource_type']) { is_expected.to eq 'course' }
            its(['resource_id']) { is_expected.to eq course.id }
            its(['title']) { is_expected.to eq course.title.to_s }
            its(['type']) { is_expected.to eq 'course_start' }
            its(['date']) { is_expected.to eq display_start_date.iso8601(3) }
          end
        end
      end

      context 'with future start_date' do
        let(:start_date) { 1.day.from_now }

        its(:size) { is_expected.to eq 1 }

        context 'date' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'course' }
          its(['resource_id']) { is_expected.to eq course.id }
          its(['title']) { is_expected.to eq course.title.to_s }
          its(['type']) { is_expected.to eq 'course_start' }
          its(['date']) { is_expected.to eq start_date.iso8601(3) }
        end

        context 'and different course states' do
          let(:course_status) { 'active' }

          describe '#active' do
            let(:course_status) { 'active' }

            its(:size) { is_expected.to eq 1 }
          end

          describe '#archive' do
            let(:course_status) { 'archive' }

            its(:size) { is_expected.to eq 1 }
          end

          describe '#preparation' do
            let(:course_status) { 'preparation' }

            its(:size) { is_expected.to eq 0 }
          end
        end

        context 'and group restriction' do
          let(:course_params) { super().merge groups: ['partners'] }

          its(:size) { is_expected.to eq 1 }
        end

        context 'without user_id' do
          let(:params) { {} }

          its(:size) { is_expected.to eq 1 }
        end

        context 'with hidden course' do
          let(:course_params) { super().merge hidden: true }

          context 'without user_id' do
            let(:params) { {} }

            its(:size) { is_expected.to eq 0 }
          end

          context 'with enrollment' do
            before { enrollment }

            its(:size) { is_expected.to eq 1 }
          end
        end

        context 'with additional course without enrollment' do
          before { create(:course, status: 'active', start_date: 3.days.from_now) }

          its(:size) { is_expected.to eq 1 }
        end

        context 'but later display_date' do
          let(:display_start_date) { 2.days.from_now }

          its(:size) { is_expected.to eq 1 }

          context 'date' do
            subject { super()[0] }

            it_behaves_like 'a date of', :course
            its(['resource_type']) { is_expected.to eq 'course' }
            its(['resource_id']) { is_expected.to eq course.id }
            its(['title']) { is_expected.to eq course.title.to_s }
            its(['type']) { is_expected.to eq 'course_start' }
            its(['date']) { is_expected.to eq display_start_date.iso8601(3) }
          end

          context 'without user_id' do
            let(:params) { {} }

            its(:size) { is_expected.to eq 1 }
          end
        end
      end
    end

    context 'type "section start"' do
      let(:params) { super().merge resource_type: 'section' }
      let(:section_params) { {start_date:} }

      before { section; enrollment }

      context 'without start_date' do
        let(:start_date) { nil }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with passed start_date' do
        let(:start_date) { 1.day.ago }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with future start_date' do
        let(:start_date) { 2.days.from_now }

        its(:size) { is_expected.to eq 1 }

        context 'with deleted enrollment' do
          let(:enrollment) { create(:deleted_enrollment, course:, user_id:) }

          its(:size) { is_expected.to eq 0 }
        end

        context 'without enrollment' do
          let(:enrollment) { nil }

          its(:size) { is_expected.to eq 0 }
        end

        context 'date' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'section' }
          its(['resource_id']) { is_expected.to eq section.id }
          its(['type']) { is_expected.to eq 'section_start' }
          its(['title']) { is_expected.to eq section.title.to_s }
          its(['date']) { is_expected.to eq start_date.iso8601(3) }
        end

        context 'not published' do
          let(:section_params) { super().merge published: false }

          its(:size) { is_expected.to eq 0 }
        end

        context 'with start but not display course start date' do
          let(:course_params) { super().merge display_start_date: 1.day.from_now }

          its(:size) { is_expected.to eq 0 }
        end
      end
    end

    context 'type "item submission_deadline"' do
      before { item; enrollment }

      let(:item_params) { {submission_deadline: deadline} }

      context 'without deadline' do
        let(:deadline) { nil }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with passed deadline' do
        let(:deadline) { 1.day.ago }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with future deadline' do
        let(:deadline) { 5.days.from_now }

        its(:size) { is_expected.to eq 1 }

        context 'without user_id' do
          let(:params) { {} }

          its(:size) { is_expected.to eq 1 }
        end

        context 'without enrollment' do
          let(:enrollment) { nil }

          its(:size) { is_expected.to eq 0 }
        end

        context 'date' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'item' }
          its(['resource_id']) { is_expected.to eq item.id }
          its(['type']) { is_expected.to eq 'item_submission_deadline' }
          its(['title']) { is_expected.to eq "#{section.title}: #{item.title}" }
          its(['date']) { is_expected.to eq deadline.iso8601(3) }
        end

        context 'not published' do
          let(:item_params) { super().merge published: false }

          its(:size) { is_expected.to eq 0 }
        end

        context 'not started' do
          let(:item_params) { super().merge start_date: DateTime.now + 2.days }

          its(:size) { is_expected.to eq 0 }
        end

        context 'with submission' do
          before { create(:result, item:, user_id:) }

          its(:size) { is_expected.to eq 0 }
        end

        context 'with submission by another user' do
          before { create(:result, item:, user_id: other_user_id) }

          its(:size) { is_expected.to eq 1 }
        end
      end
    end

    context 'type "item_submission_publishing"' do
      before { item; enrollment; result }

      let(:item_params) { {submission_publishing_date: publishing_date} }
      let(:result) { create(:result, item:, user_id:) }

      context 'without deadline' do
        let(:publishing_date) { nil }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with passed deadline' do
        let(:publishing_date) { 1.day.ago }

        its(:size) { is_expected.to eq 0 }
      end

      context 'with future deadline' do
        let(:publishing_date) { 5.days.from_now }

        its(:size) { is_expected.to eq 1 }

        context 'without user_id' do
          let(:params) { {} }

          its(:size) { is_expected.to eq 0 }

          context 'with filter all' do
            let(:params) { super().merge all: 'true' }

            its(:size) { is_expected.to eq 0 }
          end
        end

        context 'without enrollment' do
          let(:enrollment) { nil }

          its(:size) { is_expected.to eq 0 }
        end

        context 'date' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'item' }
          its(['resource_id']) { is_expected.to eq item.id }
          its(['title']) { is_expected.to eq "#{section.title}: #{item.title}" }
          its(['type']) { is_expected.to eq 'item_submission_publishing' }
          its(['date']) { is_expected.to eq publishing_date.iso8601(3) }
        end

        context 'without submission' do
          let(:result) { nil }

          its(:size) { is_expected.to eq 0 }
        end

        context 'with submission by another user' do
          let(:result) { create(:result, item:, user_id: other_user_id) }

          its(:size) { is_expected.to eq 0 }
        end
      end
    end

    context 'filters' do
      context 'course_id' do
        let(:params) { super().merge course_id: course.id }
        let!(:course) { create(:course, start_date: DateTime.now + 1.day, status: 'active') }

        before do
          enrollment
          create(:course, start_date: DateTime.now + 3.days)
        end

        its(:size) { is_expected.to eq 1 }

        context 'date' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'course' }
          its(['resource_id']) { is_expected.to eq course.id }
          its(['type']) { is_expected.to eq 'course_start' }
          its(['title']) { is_expected.to eq course.title }
          its(['date']) { is_expected.to eq course.start_date.iso8601(3) }
        end
      end

      context 'type' do
        let(:params) do
          {
            user_id:,
            type: 'item_submission_deadline,section_start',
          }
        end

        let(:dates) { (1..5).map {|i| Time.zone.now + i.days } }
        let(:other_course) { create(:course, start_date: dates[4], status: 'active') }

        let(:other_enrollment) { create(:enrollment, user_id:, course: other_course) }
        let(:third_enrollment) { create(:enrollment, user_id:, course: third_course) }

        let(:third_course) { create(:course, status: 'active') }
        let(:third_section) { create(:section, course: third_course, start_date: dates[2]) }
        let(:third_other_section) { create(:section, course: third_course, start_date: nil) }
        let(:third_item) { create(:item, section: third_other_section, submission_publishing_date: dates[3]) }

        let(:other_section) { create(:section, course:, start_date: dates[1]) }
        let(:item_params) { {submission_deadline: dates[0]} }

        before do
          enrollment
          other_enrollment
          third_enrollment

          other_course
          third_section
          other_section
          item
          third_item
          create(:result, user_id:, item: third_item, dpoints: 304)
        end

        it 'is ordered by course position' do
          action
          dates = json

          expect(dates.size).to eq 3

          types = dates.pluck('type').uniq

          expect(types).to match_array %w[
            section_start
            item_submission_deadline
          ]
        end
      end
    end

    context 'order' do
      context 'by date within courses; and courses by their first date' do
        let(:dates) { (1..5).map {|i| Time.zone.now + i.days } }
        let(:other_course) { create(:course, start_date: dates[4], status: 'active') }

        let(:other_enrollment) { create(:enrollment, user_id:, course: other_course) }
        let(:third_enrollment) { create(:enrollment, user_id:, course: third_course) }

        let(:third_course) { create(:course, status: 'active', start_date: 2.months.ago, end_date: 1.month.ago) }
        let(:third_section) { create(:section, course: third_course, start_date: dates[2]) }
        let(:third_other_section) { create(:section, course: third_course, start_date: nil) }
        let(:third_item) { create(:item, section: third_other_section, submission_publishing_date: dates[3]) }

        let(:other_section) { create(:section, course:, start_date: dates[1]) }
        let(:item_params) { {submission_deadline: dates[0]} }

        before do
          enrollment
          other_enrollment
          third_enrollment

          other_course
          third_section
          other_section
          item
          third_item
          create(:result, user_id:, item: third_item, dpoints: 304)
        end

        its(:size) { is_expected.to eq 5 }

        context 'dates[0]' do
          subject { super()[0] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'item' }
          its(['resource_id']) { is_expected.to eq item.id }
          its(['type']) { is_expected.to eq 'item_submission_deadline' }
          its(['date']) { is_expected.to eq item.submission_deadline.iso8601(3) }
        end

        context 'dates[1]' do
          subject { super()[1] }

          it_behaves_like 'a date of', :course
          its(['resource_type']) { is_expected.to eq 'section' }
          its(['resource_id']) { is_expected.to eq other_section.id }
          its(['type']) { is_expected.to eq 'section_start' }
          its(['title']) { is_expected.to eq other_section.title }
          its(['date']) { is_expected.to eq other_section.start_date.iso8601(3) }
        end

        context 'dates[2]' do
          subject { super()[2] }

          it_behaves_like 'a date of', :third_course
          its(['resource_type']) { is_expected.to eq 'section' }
          its(['resource_id']) { is_expected.to eq third_section.id }
          its(['type']) { is_expected.to eq 'section_start' }
          its(['title']) { is_expected.to eq third_section.title }
          its(['date']) { is_expected.to eq third_section.start_date.iso8601(3) }
        end

        context 'dates[3]' do
          subject { super()[3] }

          it_behaves_like 'a date of', :third_course
          its(['resource_type']) { is_expected.to eq 'item' }
          its(['resource_id']) { is_expected.to eq third_item.id }
          its(['type']) { is_expected.to eq 'item_submission_publishing' }
          its(['date']) { is_expected.to eq third_item.submission_publishing_date.iso8601(3) }
        end

        context 'dates[4]' do
          subject { super()[4] }

          it_behaves_like 'a date of', :other_course
          its(['resource_type']) { is_expected.to eq 'course' }
          its(['resource_id']) { is_expected.to eq other_course.id }
          its(['type']) { is_expected.to eq 'course_start' }
          its(['title']) { is_expected.to eq other_course.title }
          its(['date']) { is_expected.to eq other_course.start_date.iso8601(3) }
        end
      end

      context 'with same date' do
        let(:date) { 1.day.from_now }

        let(:section_params) { super().merge position: 1 }
        let(:other_section) { create(:section, course:, start_date: date, position: 3) }
        let(:third_section) { create(:section, course:, start_date: date, position: 2) }
        let(:item_params) { {submission_deadline: date, position: 2} }
        let(:third_item) { create(:item, section:, submission_publishing_date: date, position: 1) }

        before do
          course
          section
          other_section
          third_section
          item
          third_item
          enrollment
          create(:result, user_id:, item: third_item, dpoints: 304)
        end

        it 'is ordered by course position' do
          action
          dates = json

          expect(dates.size).to eq 4

          dates.each do |d|
            expect(d['date']).to eq date.iso8601(3)
            expect(d['course_id']).to eq course.id
            expect(d['course_code']).to eq course.course_code
            expect(d['course_title']).to eq course.title
          end

          expect(dates[0]).to include(
            'resource_type' => 'item',
            'resource_id' => third_item.id,
            'type' => 'item_submission_publishing'
          )

          expect(dates[1]).to include(
            'resource_type' => 'item',
            'resource_id' => item.id,
            'type' => 'item_submission_deadline'
          )

          expect(dates[2]).to include(
            'resource_type' => 'section',
            'resource_id' => third_section.id,
            'type' => 'section_start'
          )

          expect(dates[3]).to include(
            'resource_type' => 'section',
            'resource_id' => other_section.id,
            'type' => 'section_start'
          )
        end
      end
    end
  end
end
