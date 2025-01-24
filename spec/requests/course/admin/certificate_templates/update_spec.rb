# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Update', type: :request do
  subject(:update_template) do
    patch "/courses/#{course.course_code}/certificate_templates/#{template.id}",
      params: {certificate_template: params},
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[certificate.template.manage course.content.access] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let!(:template) { create(:certificate_template, :roa, course:, qrcode_x: 300) }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:params) { {qrcode_x: 333} }
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
  let(:list_stub) do
    stub_request(:get,
      'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
      "prefix=uploads/#{upload_id}")
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
    upload_stub
    list_stub
    store_stub
  end

  it 'updates the certificate template' do
    expect { update_template }.to change { template.reload.qrcode_x }.from(300).to(333)
    expect(response).to redirect_to "/courses/#{course.course_code}/certificate_templates"
    expect(flash[:success].first).to eq 'The template has been updated.'
  end

  context 'with valid file upload' do
    let(:params) { {file_upload_id: upload_id} }

    it 'replaces the existing template file' do
      expect { update_template }.to change { template.reload.file_uri }
      expect(store_stub).to have_been_requested
      expect(response).to redirect_to "/courses/#{course.course_code}/certificate_templates"
      expect(flash[:success].first).to eq 'The template has been updated.'
    end
  end

  context 'with rejected file upload' do
    let(:params) { {file_upload_id: upload_id} }
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
      update_template
      expect(store_stub).not_to have_been_requested
      expect(response).to render_template :edit
      expect(flash[:error].first).to eq 'The template has not been updated.'
    end
  end

  context 'with file upload error (during validation)' do
    let(:params) { {file_upload_id: upload_id} }
    let(:upload_stub) do
      stub_request(:head, file_url).to_return(status: 403)
    end

    it 'displays an error message' do
      update_template
      expect(store_stub).not_to have_been_requested
      expect(response).to render_template :edit
      expect(flash[:error].first).to eq 'The template has not been updated.'
    end
  end

  context 'with empty file upload' do
    let(:params) { super().merge(file_upload_id: upload_id) }
    let(:list_stub) do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads/#{upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
            </ListBucketResult>
          XML
    end

    it 'updates all params but the file upload' do
      expect { update_template }.to change { template.reload.qrcode_x }.from(300).to(333)
      expect(store_stub).not_to have_been_requested
      expect(response).to redirect_to "/courses/#{course.course_code}/certificate_templates"
      expect(flash[:success].first).to eq 'The template has been updated.'
    end
  end

  context 'with file upload error (when copying the upload)' do
    let(:params) { {file_upload_id: upload_id} }
    let(:store_stub) do
      stub_request(:put, %r{
        https://s3.xikolo.de/xikolo-certificate/templates/[0-9a-zA-Z]+.pdf
      }x).to_return(status: 403, body: '<xml></xml>')
    end

    it 'displays an error message' do
      update_template
      expect(store_stub).to have_been_requested
      expect(response).to render_template :edit
      expect(flash[:error].first).to eq 'The template has not been updated.'
    end
  end

  context 'without permission to manage certificate templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      update_template
      expect(response).to redirect_to '/'
      expect(flash[:error].first).to eq 'You do not have sufficient permissions for this action.'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      update_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      update_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
