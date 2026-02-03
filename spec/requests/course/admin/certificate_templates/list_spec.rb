# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: List', type: :request do
  subject(:list_templates) do
    get "/courses/#{course.course_code}/certificate_templates",
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }

  before do
    stub_user_request(permissions:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    create(:certificate_template, :cop)
    create(:certificate_template, :roa, course:)
  end

  it 'lists all certificate templates for the course' do
    list_templates
    expect(response.body).to include 'Record of Achievement'
    expect(response.body).not_to include 'Confirmation of Participation'
    expect(response.body).to include 'Add new template'
  end

  context 'without permission to manage certificate templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to '/'
      expect(flash[:error].first).to eq 'You do not have sufficient permissions for this action.'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
