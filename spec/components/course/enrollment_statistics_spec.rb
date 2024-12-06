# frozen_string_literal: true

require 'spec_helper'

describe Course::EnrollmentStatistics, type: :component do
  subject(:component) { described_class.new course_presenter, user: }

  let(:course) { create(:course, start_date:, end_date:) }
  let(:start_date) { 4.weeks.ago }
  let(:end_date) { 2.days.ago }
  let(:external) { false }
  let(:course_presenter) do
    instance_double(Course::CourseDetailsPresenter,
      id: course.id,
      effective_start_date: start_date,
      end_date:,
      external?: external)
  end
  let(:anonymous) { true }
  let(:permissions) { [] }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'features' => [],
      'permissions' => permissions,
      'user' => {'anonymous' => anonymous}
    )
  end

  context 'with the course still running' do
    let(:end_date) { 1.week.from_now }

    context 'with enrollment threshold of 500 surpassed' do
      before do
        create_list(:enrollment, 501, course:) # rubocop:disable FactoryBot/ExcessiveCreateList
      end

      it 'renders the (basic) enrollment count' do
        render_inline(component)

        expect(page).to have_css '.course-enrollment-count'
        expect(page).to have_content 'Learners enrolled:'
        expect(page).to have_no_selector '.enrollment-statistics'
      end
    end

    context 'with enrollment threshold of 500 not surpassed' do
      before do
        create_list(:enrollment, 499, course:) # rubocop:disable FactoryBot/ExcessiveCreateList
      end

      it 'does not render the component (esp. not the basic enrollment count)' do
        render_inline(component)

        expect(page).to have_no_selector '.course-enrollment-count'
        expect(page).to have_no_selector '.enrollment-statistics'
      end

      context 'with permission to see the enrollment count' do
        let(:anonymous) { false }
        let(:permissions) { %w[course.enrollment_counter.view] }

        it 'renders the basic enrollment count' do
          render_inline(component)

          expect(page).to have_css '.course-enrollment-count'
          expect(page).to have_content 'Learners enrolled:'
          expect(page).to have_no_selector '.enrollment-statistics'
        end
      end
    end
  end

  context 'with the course ended' do
    it 'renders the detailed enrollment statistics' do
      render_inline(component)

      expect(page).to have_no_selector '.course-enrollment-count'
      expect(page).to have_no_content 'Learners enrolled:'
      expect(page).to have_css '.enrollment-statistics__row[data-type="current"]'
      expect(page).to have_css '.enrollment-statistics__row[data-type="course_end"]'
      expect(page).to have_css '.enrollment-statistics__row[data-type="course_start"]'
    end

    context 'with specific enrollment data missing' do
      before do
        create_list(:enrollment, 2, course:, created_at: start_date - 1.day)
        create_list(:enrollment, 3, course:, created_at: end_date - 1.week)
      end

      it 'renders the available enrollment statistics' do
        render_inline(component)

        expect(page).to have_no_selector '.course-enrollment-count'
        expect(page).to have_no_content 'Learners enrolled:'
        expect(page).to have_css '.enrollment-statistics__row[data-type="current"]'
        expect(page).to have_css '.enrollment-statistics__row[data-type="course_start"]'
      end
    end
  end
end
