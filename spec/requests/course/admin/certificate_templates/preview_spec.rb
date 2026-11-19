# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Preview', type: :request do
  subject(:request) { get "/learn/#{course.id}/certificate_templates/#{certificate_template.id}/preview" }

  let(:user) { create(:'account_service/user') }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course, course_code: 'my-course') }
  let(:certificate_template) { create(:certificate_template, :roa, course:) }

  before do
    sign_in(user:)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(build(:'course:course', id: course.id))

    stub_request(:get, "#{test_s3_host}/xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf")
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
