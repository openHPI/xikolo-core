# frozen_string_literal: true

require 'spec_helper'

describe Course::EntryAction, type: :component do
  subject(:component) { described_class.new(course_id: course.id, user:) }

  let(:course) { create(:'course_service/course', :active) }
  let(:user_id) { create(:'account_service/user').id }
  let(:user) { instance_double(CurrentUser::User, id: user_id, anonymous?: false) }

  it 'offers enrollment to an unenrolled user' do
    render_inline(component)

    expect(page).to have_link('Enroll for the course', href: "/enrollments?course_id=#{course.course_code}")
  end

  context 'with an active enrollment' do
    before { create(:'course_service/enrollment', course:, user_id:) }

    it 'offers entry through the resume route' do
      render_inline(component)

      expect(page).to have_link('Continue learning', href: "/learn/#{course.course_code}/resume")
    end

    it 'does not offer entry before the course starts' do
      course.update!(start_date: 1.day.from_now)
      render_inline(component)

      expect(page).to have_no_link
    end

    it 'allows entry to an invite-only course' do
      course.update!(invite_only: true)
      render_inline(component)

      expect(page).to have_link('Continue learning')
    end
  end

  it 'allows re-enrollment after an enrollment was deleted' do
    create(:'course_service/enrollment', course:, user_id:, deleted: true)
    render_inline(component)

    expect(page).to have_link('Enroll for the course')
  end

  it 'does not offer self-enrollment in an invite-only course' do
    course.update!(invite_only: true)
    render_inline(component)

    expect(page).to have_no_link
  end

  it 'does not offer internal actions for an external course' do
    course.update!(external_course_url: 'https://example.org/course')
    render_inline(component)

    expect(page).to have_no_link
  end

  context 'with an anonymous user' do
    let(:user) { instance_double(CurrentUser::AnonymousUser, anonymous?: true) }

    it 'uses the existing enrollment route to enter the login flow' do
      render_inline(component)

      expect(page).to have_link('Enroll for the course', href: "/enrollments?course_id=#{course.course_code}")
    end
  end
end
