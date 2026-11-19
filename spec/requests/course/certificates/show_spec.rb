# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Show', type: :request do
  subject(:show_certificate) { get "/learn/#{course.id}/certificate" }

  let(:course) { create(:course, course_code: 'my-course', records_released: true) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:user) { create(:'account_service/user') }
  let!(:certificate_template) { create(:certificate_template, :roa, course:) }
  let(:enrollment) do
    create(
      :'course_service/enrollment',
      :with_evaluation,
      course_id: course.id,
      quantiled_user_dpoints: 90,
      user_id: user.id,
      completed: false,
      quantile: 0.9,
      deleted: false
    )
  end

  before do
    xi_config file_fixture('badge_config.yml').read

    sign_in(user:)

    enrollment
  end

  context 'with achieved certificate (RoA)' do
    let(:record) { create(:roa, course:, user_id: user.id, template: certificate_template) }

    before { record }

    it 'shows the certificate (RoA)' do
      show_certificate
      expect(response).to have_http_status :ok
      expect(response.body).to include 'Certificate'
      expect(response.body).to include course.title
    end
  end

  context 'with no certificate (RoA) achieved for the course' do
    let(:enrollment) do
      create(
        :'course_service/enrollment',
        :with_low_evaluation,
        course_id: course.id,
        quantiled_user_dpoints: 90,
        user_id: user.id,
        completed: false,
        quantile: 0.9
      )
    end

    it 'responds with 404 Not Found' do
      expect { show_certificate }.to raise_error AbstractController::ActionNotFound
    end
  end
end
