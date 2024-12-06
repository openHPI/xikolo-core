# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Open Badge Templates: List', type: :request do
  subject(:list_templates) do
    get "/courses/#{course.course_code}/open_badge_templates",
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }

  before do
    stub_user_request(permissions:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    create(:open_badge_template, name: 'Open Badge Template No. 1')
    create(:open_badge_template, name: 'Open Badge Template No. 2', course:)
  end

  it 'lists all Open Badge templates for the course' do
    list_templates
    expect(response.body).to include 'Open Badge Template No. 2'
    expect(response.body).not_to include 'Open Badge Template No. 1'
  end

  context 'without permission to manage Open Badge templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
