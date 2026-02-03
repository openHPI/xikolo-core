# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Preview', type: :request do
  subject(:request) { get "/courses/#{course.id}/certificate_templates/#{certificate_template.id}/preview", headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user) { create(:user, :with_email) }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course, course_code: 'my-course') }
  let(:certificate_template) { create(:certificate_template, :roa, course:) }

  before do
    stub_user_request(id: user.id, permissions:)

    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(build(:'course:course', id: course.id))

    stub_request(:get, 'https://s3.xikolo.de/xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf')
      .to_return(body: File.new('spec/support/files/certificate/template.pdf'), status: 200)
  end

  it 'delivers a PDF' do
    request
    expect(response).to have_http_status :ok
    expect(response.header['Content-Type']).to eq 'application/pdf'
    expect(response.header['Content-Disposition']).to include 'my-course_record_preview.pdf'
    # %PDF is the magic number for PDF files
    expect(response.body).to start_with '%PDF'
  end
end
