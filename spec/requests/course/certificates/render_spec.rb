# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Render', type: :request do
  subject(:request) { get '/certificate/render', params:, headers: }

  let(:params) { {course_id: course.id, type: certificate_type} }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, course_code: 'my-course', records_released: true) }
  let(:course_resource) { build(:'course:course', id: course.id) }

  before do
    stub_user_request id: user.id

    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(course_resource)

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
    ).to_return(
      Stub.json(
        build_list(
          :'course:enrollment', 1,
          course_id: course.id,
          user_id: user.id,
          points: {achieved: 90, maximal: 100, percentage: 90},
          certificates: {record_of_achievement: true, certificate: true},
          quantile: 0.99
        )
      )
    )

    stub_request(:get, 'https://s3.xikolo.de/xikolo-certificate/templates/1YLgUE6KPhaxfpGSZ.pdf')
      .to_return(body: File.new('spec/support/files/certificate/template.pdf'), status: 200)

    create(:enrollment, user_id: user.id, course:)
  end

  context '(Certificate)' do
    let(:certificate_type) { 'Certificate' }

    before { create(:certificate_template, :certificate, course:) }

    it 'renders the certificate' do
      request
      expect(response).to have_http_status :ok
      expect(response.header['Content-Type']).to eq 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'my-course_Certificate.pdf'
    end
  end

  context '(Record of Achievement)' do
    let(:certificate_type) { 'RecordOfAchievement' }

    before { create(:certificate_template, :roa, course:) }

    it 'renders the RoA' do
      request
      expect(response).to have_http_status :ok
      expect(response.header['Content-Type']).to eq 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'my-course_RecordOfAchievement.pdf'
    end
  end
end
