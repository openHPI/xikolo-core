# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Render', type: :request do
  subject(:request) { get '/certificate/render', params: }

  let(:params) { {course_id: course.id, type: certificate_type} }
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, course_code: 'my-course', records_released: true) }
  let(:course_resource) { build(:'course:course', id: course.id) }
  let(:enrollment_with_evaluation) do
    create(
      :'course_service/enrollment',
      :with_evaluation,
      course_id: course.id,
      quantiled_user_dpoints: 100,
      user_id: user.id,
      completed: true,
      quantile: 0.99,
      deleted: false
    )
  end

  before do
    sign_in(user:)
    enrollment_with_evaluation

    stub_request(:get, "#{test_s3_host}/xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf")
      .to_return(body: File.new('spec/support/files/certificate/template.pdf'), status: 200)
  end

  context '(Certificate)' do
    let(:certificate_type) { 'Certificate' }

    before { create(:certificate, user:, course:) }

    it 'renders the certificate' do
      request
      expect(response).to have_http_status :ok
      expect(response.header['Content-Type']).to eq 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'my-course_Certificate.pdf'
    end

    it 'serves the stored PDF without rendering it again' do
      expect(Certificate::RecordRenderer).not_to receive(:as_pdf)
      request
    end
  end

  context 'Certificate (RoA)' do
    let(:certificate_type) { 'RecordOfAchievement' }

    before { create(:certificate_template, :roa, course:) }

    it 'renders the certificate (RoA)' do
      request
      expect(response).to have_http_status :ok
      expect(response.header['Content-Type']).to eq 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'my-course_RecordOfAchievement.pdf'
    end

    context 'for a course in preparation status' do
      let(:course) { create(:course, course_code: 'my-course', records_released: true, published: false) }

      it 'still renders the certificate (RoA)' do
        request
        expect(response).to have_http_status :ok
        expect(response.header['Content-Type']).to eq 'application/pdf'
        expect(response.header['Content-Disposition']).to include 'my-course_RecordOfAchievement.pdf'
      end
    end
  end
end
