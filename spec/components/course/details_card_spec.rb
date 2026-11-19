# frozen_string_literal: true

require 'spec_helper'

describe Course::DetailsCard, type: :component do
  subject(:component) { described_class.new(presenter, **options) }

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }
  let(:course) { create(:'course_service/course', **course_attrs) }
  let(:course_attrs) { {title: 'Digital Justice', course_format: 'project', alternative_teacher_text: 'Jennifer Fritz'} }
  let(:presenter) { Course::CourseDetailsPresenter.new(course:, user:, enrollments:) }
  let(:enrollments) { nil }
  let(:options) { {} }

  it 'renders the title, format and teachers' do
    render_inline(component)

    expect(page).to have_css 'h2', text: 'Digital Justice'
    expect(page).to have_css '.x-badge-neutral', text: 'Project'
    expect(page).to have_text 'Offered by Jennifer Fritz'
  end

  it 'offers to enroll' do
    render_inline(component)

    expect(page).to have_link 'Enroll now'
    expect(page).to have_no_link 'Un-enroll'
  end

  it 'hides the enrollment count by default' do
    render_inline(component)

    expect(page).to have_no_text 'enrollments'
  end

  context 'with an enrollment count' do
    let(:options) { {enrollment_count: 1000} }

    it 'shows it' do
      render_inline(component)

      expect(page).to have_text '1000 enrollments'
    end
  end

  context 'with public classifiers' do
    let(:cluster) { create(:'course_service/cluster', visible: true) }
    let(:classifier) { create(:'course_service/classifier', cluster:, translations: {'en' => 'Bias'}) }
    let(:course_attrs) { super().merge(classifiers: [classifier]) }

    it 'renders them as badges' do
      render_inline(component)

      expect(page).to have_css 'li.x-badge', text: 'Bias'
    end
  end

  context 'for an upcoming course' do
    let(:course_attrs) { super().merge(start_date: 3.days.from_now, display_start_date: nil) }

    it 'counts down to the start' do
      render_inline(component)

      expect(page).to have_text 'Starts in'
      expect(page).to have_css('[data-controller="countdown"]')
      expect(page).to have_css('.sr-only', text: 'Course starts on')
    end
  end

  context 'for a started course' do
    let(:course_attrs) { super().merge(start_date: 3.days.ago, display_start_date: nil) }

    it 'shows no countdown' do
      render_inline(component)

      expect(page).to have_no_css('[data-controller="countdown"]')
    end
  end

  context 'for an external course' do
    let(:course_attrs) { super().merge(external_course_url: 'https://example.com/external') }

    it 'links to the external course only' do
      render_inline(component)

      expect(page).to have_link 'Go to external course', href: 'https://example.com/external'
      expect(page).to have_no_link 'Enroll now'
    end
  end

  context 'for an invite-only course' do
    let(:course_attrs) { super().merge(invite_only: true) }

    it 'does not offer to enroll' do
      render_inline(component)

      expect(page).to have_no_link 'Enroll now'
    end
  end

  context 'when enrolled' do
    let(:session) { create(:'account_service/session') }
    let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
    let(:enrollments) { [create(:'course_service/enrollment', course:, user_id: user.id)] }

    it 'offers to enter and un-enroll' do
      render_inline(component)

      expect(page).to have_link 'Continue course'
      expect(page).to have_link 'Un-enroll'
      expect(page).to have_no_link 'Enroll now'
    end

    context 'for a course that has not started yet' do
      let(:course_attrs) { super().merge(start_date: 3.days.from_now, display_start_date: nil) }

      it 'only offers to un-enroll' do
        render_inline(component)

        expect(page).to have_link 'Un-enroll'
        expect(page).to have_no_link 'Continue course'
        expect(page).to have_no_css '.x-btn-disabled'
      end
    end
  end
end
