# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Open Badge Templates: Create', type: :request do
  subject(:create_template) do
    post "/courses/#{course.course_code}/open_badge_templates",
      params: {open_badge_template: params},
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:params) do
    {
      name: 'OpenBadeTemplateName',
      file_upload_id: upload_id,
    }
  end
  let(:file_url) do
    'https://s3.xikolo.de/xikolo-uploads/' \
      'uploads/f13d30d3-6369-4816-9695-af5318c8ac15/template.png'
  end
  let(:upload_stub) do
    stub_request(:put, %r{
      https://s3.xikolo.de/xikolo-certificate/openbadge_templates/[0-9a-zA-Z]+.png
    }x).to_return(status: 200, body: '<xml></xml>')
  end

  before do
    stub_user_request(permissions:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])

    stub_request(:get,
      'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
      "prefix=uploads%2F#{upload_id}") \
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/#{upload_id}</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/#{upload_id}/template.png</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'certificate_openbadge_template',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
    upload_stub
  end

  it 'creates a new Open Badge template' do
    expect { create_template }.to change(Certificate::OpenBadgeTemplate, :count).from(0).to(1)
    expect(Certificate::OpenBadgeTemplate.first).to match an_object_having_attributes(
      course_id: course.id,
      name: 'OpenBadeTemplateName'
    )
    expect(upload_stub).to have_been_requested
    expect(response).to redirect_to "/courses/#{course.course_code}/open_badge_templates"
    expect(flash[:success].first).to eq 'The Open Badge template has been created.'
  end

  context 'without file upload' do
    let(:params) { super().merge file_upload_id: nil }

    it 'displays an error message' do
      expect { create_template }.not_to change(Certificate::OpenBadgeTemplate, :count).from(0)
      expect(response).to render_template :new
      expect(flash[:error].first).to eq 'The Open Badge template has not been created.'
    end
  end

  context 'without permission to manage Open Badge templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end
