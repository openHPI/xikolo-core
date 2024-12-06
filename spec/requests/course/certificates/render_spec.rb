# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Render', type: :request do
  subject(:request) { get '/certificate/render', params:, headers: }

  let(:params) { {course_id: course.id, type: certificate_type} }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user) { create(:user, :with_email) }
  let(:course) { create(:course, :offers_proctoring, course_code: 'my-course', records_released: true) }
  let(:course_resource) { build(:'course:course', :proctored, id: course.id) }

  before do
    stub_user_request id: user.id

    Stub.service(:course, build(:'course:root'))
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
    stub_request(:head, %r{https://s3.xikolo.de/xikolo-certificate/proctoring/[0-9a-zA-Z]+/[0-9a-zA-Z]+.jpg}x)
      .to_return(status: 200)
    stub_request(:get, %r{https://s3.xikolo.de/xikolo-certificate/proctoring/[0-9a-zA-Z]+/[0-9a-zA-Z]+.jpg}x)
      .to_return(body: File.new('spec/support/files/proctoring/user_certificate_image.jpg'), status: 200)

    create(:enrollment, :proctored, user_id: user.id, course:)
  end

  context '(Certificate)' do
    let(:certificate_type) { 'Certificate' }
    let(:proctoring_passed) { true }

    before do
      allow(Proctoring::SmowlAdapter).to receive(:new).and_wrap_original do |m, *args|
        m.call(*args).tap do |adapter|
          allow(adapter).to receive(:passed?).and_return proctoring_passed
        end
      end

      create(:certificate_template, :certificate, course:)
    end

    it 'renders the certificate' do
      request
      expect(response).to have_http_status :ok
      expect(response.header['Content-Type']).to eq 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'my-course_Certificate.pdf'
    end

    context 'when the user did not pass proctoring' do
      let(:proctoring_passed) { false }

      it 'does not render the certificate' do
        expect { request }.to raise_error AbstractController::ActionNotFound
      end
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
