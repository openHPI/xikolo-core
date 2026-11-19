# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: List', type: :request do
  subject(:list_templates) do
    get "/learn/#{course.course_code}/certificate_templates"
  end

  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }

  before do
    sign_in(user:) if authenticate
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)

    create(:certificate_template, :cop)
    create(:certificate_template, :roa, course:)
  end

  it 'lists all certificate templates for the course' do
    list_templates
    expect(response.body).to include 'Certificate'
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
      expect(response).to redirect_to "/learn/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects the user' do
      list_templates
      expect(response).to redirect_to "/learn/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
