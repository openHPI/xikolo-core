# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Open Badge Templates: Destroy', type: :request do
  subject(:delete_template) do
    delete "/courses/#{course.course_code}/open_badge_templates/#{template.id}",
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let!(:template) do
    create(:open_badge_template,
      course:,
      file_uri: 's3://xikolo-certificate/badge_templates/abc.svg')
  end
  let!(:delete_stub) do
    stub_request(
      :delete,
      'https://s3.xikolo.de/xikolo-certificate/badge_templates/abc.svg'
    ).to_return(status: 200)
  end

  before do
    stub_user_request(permissions:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  it 'deletes the Open Badge template' do
    expect { delete_template }.to change(Certificate::OpenBadgeTemplate, :count).from(1).to(0)
    expect(response).to redirect_to "/courses/#{course.course_code}/open_badge_templates"
  end

  it 'removes the referenced S3 object' do
    delete_template
    expect(delete_stub).to have_been_requested
  end

  context 'without permission to manage Open Badge templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
