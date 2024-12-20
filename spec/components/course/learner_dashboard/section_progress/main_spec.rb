# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerDashboard::SectionProgress::Main, type: :component do
  subject(:component) do
    described_class.new(section_progress, course)
  end

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:section_progress) { build(:'course:section_progress', title: 'Section 1') }
  let(:course) { create(:course) }
  let(:course_id) { course.id }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let(:request_context_id) { course_context_id }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user_id' => user_id,
      'user' => {'anonymous' => false}
    )
  end

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}',
      user_url: '/users/{id}'
    )
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      sections_url: '/sections',
      progresses_url: '/progresses'
    )

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      status: 'active',
      course_code: course.course_code,
      title: 'Test Course',
      context_id: course_context_id,
    })
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:, learning_evaluation: 'true'}
    ).to_return Stub.json([
      {
        course_id:,
        certificates: [],
      },
    ])
  end

  it 'shows the section title' do
    render_inline(component)

    expect(page).to have_content 'Section 1'
  end

  it 'shows information about the section progress title bar' do
    render_inline(component)

    expect(page).to have_content 'Graded: 100%'
    expect(page).to have_content 'Self-tests: 100%'
    expect(page).to have_content 'Visited: 93%'
    expect(page).to have_content '15 of 16 items visited'
  end

  it 'shows information about the section material' do
    render_inline(component)

    expect(page).to have_content 'Section material'
    expect(page).to have_css '[aria-label="Week 1: Quiz 1"]'
    expect(page).to have_css '[aria-label="Week 1: Quiz 2"]'
  end

  it 'shows information about the section statistics' do
    render_inline(component)

    expect(page).to have_content 'Section statistics'
    expect(page).to have_content 'Assignments22.0 / 26.0 (84%)'
    expect(page).to have_content '3 of 4 taken'
    expect(page).to have_content 'Bonus5.0 / 8.0 (62%)'
    expect(page).to have_content '1 of 1 taken'
    expect(page).to have_content 'Self-tests4.0 / 4.0 (100%)'
    expect(page).to have_content '2 of 2 taken'
  end
end
