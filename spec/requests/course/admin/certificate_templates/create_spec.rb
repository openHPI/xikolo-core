# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Create', type: :request do
  subject(:create_template) do
    post "/courses/#{course.course_code}/certificate_templates",
      params: {certificate_template: params},
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[certificate.template.manage course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:params) do
    attributes_for(:certificate_template, :roa, course:)
      .merge(file_upload_id: upload_id)
  end
  let(:file_url) do
    "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/template.pdf"
  end
  let(:upload_stub) do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'certificate_template',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:store_stub) do
    stub_request(:put, %r{
      https://s3.xikolo.de/xikolo-certificate/templates/[0-9a-zA-Z]+.pdf
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
      "prefix=uploads/#{upload_id}") \
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
              <Key>uploads/#{upload_id}/template.pdf</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
    upload_stub
    store_stub
  end

  it 'creates a new certificate template' do
    expect { create_template }.to change(Certificate::Template, :count).from(0).to(1)
    expect(Certificate::Template.first).to match an_object_having_attributes(
      course_id: course.id,
      certificate_type: 'RecordOfAchievement'
    )
    expect(upload_stub).to have_been_requested
    expect(response).to redirect_to "/courses/#{course.course_code}/certificate_templates"
    expect(flash[:success].first).to eq 'The template has been created.'
  end

  context 'with rejected file upload' do
    let(:upload_stub) do
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'certificate_template',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )
    end

    it 'displays an error message' do
      expect { create_template }.not_to change(Certificate::Template, :count).from(0)
      expect(response).to render_template :new
      expect(flash[:error].first).to eq 'The template has not been created.'
    end
  end

  context 'without file upload' do
    let(:params) { super().merge file_upload_id: nil }

    it 'displays an error message' do
      expect { create_template }.not_to change(Certificate::Template, :count).from(0)
      expect(response).to render_template :new
      expect(flash[:error].first).to eq 'The template has not been created.'
    end
  end

  context 'without permission to manage certificate templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to '/'
      expect(flash[:error].first).to eq 'You do not have sufficient permissions for this action.'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      create_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
