# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Verify', type: :request do
  subject(:verify_response) { verify_request; response }

  let(:verify_request) { get "/verify/#{verification_code}" }
  let(:verification_code) { 'jazzy-fuzzy-juicy-junky-pizza' }
  let(:course) { create(:course, records_released: true) }
  let(:user) { create(:'account_service/user') }
  let(:record) { create(:roa, verification: verification_code, course:, user_id: user.id) }
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

    enrollment
  end

  describe '(prevent search engine indexing)' do
    before { record }

    it 'contains the noindex meta tag' do
      expect(verify_response.body).to include '<meta name="robots" content="noindex">'
    end
  end

  it 'responds with 404 Not Found with unknown verification code' do
    expect { verify_request }.to raise_error AbstractController::ActionNotFound
  end

  describe 'for certificate (RoA)' do
    before { record }

    it 'renders a verification page' do
      expect(verify_response.body).to include "The certificate for the verification code <i>#{verification_code}</i> is valid."
      expect(verify_response.body).to include 'Certificate type: Certificate'
      expect(verify_response.body).to include course.title
    end
  end

  describe 'for Confirmation of Participation' do
    let(:record) { create(:cop, verification: verification_code, course:, user_id: user.id) }

    before { record }

    it 'renders a verification page' do
      expect(verify_response.body).to include "The certificate for the verification code <i>#{verification_code}</i> is valid."
      expect(verify_response.body).to include 'Certificate type: Confirmation of Participation'
    end
  end

  describe '(meta tags)' do
    before { record }

    it 'contains the Open Graph meta tags' do
      expect(verify_response.body).to include "<meta property=\"og:title\" content=\"Certificate Details - #{course.title}\">"
      expect(verify_response.body).to include '<meta property="og:type" content="website">'
      expect(verify_response.body).to include '<meta property="og:url" content="http://www.example.com/verify/jazzy-fuzzy-juicy-junky-pizza">'
      expect(verify_response.body).to include "<meta property=\"og:description\" content=\"openHPI verifies that the candidate completed the course #{course.title} and passed the necessary exercises and exams to earn a course certificate.\">"
      expect(verify_response.body).to include '<meta property="og:site_name" content="Xikolo">'
    end
  end
end
