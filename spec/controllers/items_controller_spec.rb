# frozen_string_literal: true

require 'spec_helper'
require 'rspec/expectations'

describe ItemsController, type: :controller do
  let(:course) { create(:course, course_code: "course-#{SecureRandom.uuid}") }
  let(:section) { create(:section, course:) }
  let(:course_resource) { build(:'course:course', id: course.id, title: course.title, course_state:, context_id: course_context.id) }
  let(:section_resource) { build(:'course:section', id: section.id, title: section.title, course_id: course.id) }

  let(:user_id) { SecureRandom.uuid }
  let(:user) { create(:'account_service/user', id: user_id) }
  let(:permissions) { [] }
  let(:course_state) { 'archive' }
  let(:course_context) { AccountService::Context.root }

  before do
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .to_return Stub.json({properties: {}})
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([{course_id: course.id, user_id:}])
    Stub.request(:course, :get, "/sections/#{section.id}").to_return Stub.json(section_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json([])
    sign_in(user: user, permissions:)
  end

  describe 'GET #new' do
    subject { get :new, params: {course_id: course.id, section_id: section.id} }

    before do
      Stub.request(:course, :get, '/items', query: {section_id: section.id, state_for: ''})
        .to_return Stub.json([])
    end

    context 'as non admin' do
      it { is_expected.to have_http_status :see_other }
    end

    context 'via get with course.content.edit permissions' do
      let(:permissions) { %w[course.content.edit course.content.access] }

      it { is_expected.to have_http_status :ok }
    end
  end
end
