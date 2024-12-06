# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Certificates: Verify', type: :request do
  subject(:verify_response) { verify_request; response }

  let(:verify_request) { get "/verify/#{verification_code}" }
  let(:verification_code) { 'jazzy-fuzzy-juicy-junky-pizza' }
  let(:course) { create(:course, records_released: true) }
  let(:user) { create(:user, :with_email) }
  let(:template) { create(:open_badge_template, course:) }
  let(:record) { create(:roa, verification: verification_code, course:, user:) }
  let(:enrollments) do
    Stub.json(
      build_list(
        :'course:enrollment', 1, :with_learning_evaluation,
        course_id: course.id,
        user_id: user.id,
        points: {achieved: 90, maximal: 100, percentage: 90},
        quantile: 0.99
      )
    )
  end

  before do
    xi_config file_fixture('badge_config.yml').read

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/enrollments',
      query: {
        user_id: user.id,
        course_id: course.id,
        learning_evaluation: true,
        deleted: true,
      }).to_return enrollments
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

  describe 'for Record of Achievement' do
    let(:open_badge) { create(:open_badge, record:, open_badge_template: template) }
    let(:file_url) { "https://s3.xikolo.de/xikolo-certificate/openbadges/#{UUID4(user.id).to_s(format: :base62)}/#{UUID4(record.id).to_s(format: :base62)}.png" }

    before do
      stub_request(:get, open_badge.open_badge_template.file_uri.gsub('s3://', 'https://s3.xikolo.de/'))
        .with(query: hash_including({}))
        .to_return(body: File.new('spec/support/files/certificate/badge_template.png'), status: 200)
      stub_request(:put, file_url)
    end

    it 'renders a verification page' do
      expect(verify_response.body).to include "The certificate for the verification code <i>#{verification_code}</i> is valid."
      expect(verify_response.body).to include 'Certificate type: Record of Achievement'
      expect(verify_response.body).to include course.title
    end

    it 'contains an Open Badge' do
      expect(verify_response.body).to include 'img class="open-badge"'
      expect(verify_response.body).to include file_url
    end

    context 'for an archived user' do
      let(:user) { create(:user, :archived) }

      before { record; template; }

      context 'with already baked Open Badge' do
        let(:open_badge) { create(:open_badge_v2, :baked, record:, open_badge_template: template) }

        it 'states that the verification is not possible' do
          expect(verify_response.body).to include 'The account of this candidate has been deleted. For this reason, we can no longer verify this certificate.'
        end

        it 'does not show the Open Badge' do
          expect(verify_response.body).not_to include 'img class="open-badge"'
          expect(verify_response.body).not_to include open_badge.file_uri.gsub('s3://', 'https://s3.xikolo.de/')
        end

        it 'does not contain the course title' do
          expect(verify_response.body).not_to include course.title
        end

        it "does not contain the deleted user's name" do
          expect(verify_response.body).not_to include user.full_name
        end

        it 'does not contain the mockup name of deleted accounts' do
          expect(verify_response.body).not_to include 'Deleted User'
        end
      end

      context 'without already baked Open Badge' do
        it 'states that the verification is not possible' do
          expect(verify_response.body).to include 'The account of this candidate has been deleted. For this reason, we can no longer verify this certificate.'
        end

        it 'does not show the Open Badge' do
          expect(verify_response.body).not_to include 'img class="open-badge"'
        end

        it 'does not contain the course title' do
          expect(verify_response.body).not_to include course.title
        end

        it "does not contain the deleted user's name" do
          expect(verify_response.body).not_to include user.full_name
        end

        it 'does not contain the mockup name of deleted accounts' do
          expect(verify_response.body).not_to include 'Deleted User'
        end
      end
    end
  end

  describe 'for Confirmation of Participation' do
    let(:record) { create(:cop, verification: verification_code, course:, user:) }

    before { record }

    it 'renders a verification page' do
      expect(verify_response.body).to include "The certificate for the verification code <i>#{verification_code}</i> is valid."
      expect(verify_response.body).to include 'Certificate type: Confirmation of Participation'
    end

    it 'does not contain an Open Badge' do
      expect(verify_response.body).not_to include('img class="open-badge"')
    end
  end

  describe '(meta tags)' do
    before { record }

    it 'contains the Open Graph meta tags' do
      expect(verify_response.body).to include "<meta property=\"og:title\" content=\"Certificate Details - #{course.title}\">"
      expect(verify_response.body).to include '<meta property="og:type" content="website">'
      expect(verify_response.body).to include '<meta property="og:url" content="http://www.example.com/verify/jazzy-fuzzy-juicy-junky-pizza">'
      expect(verify_response.body).to include "<meta property=\"og:description\" content=\"Xikolo verifies that the candidate completed the course #{course.title} and passed the necessary exercises and exams to earn a course certificate.\">"
      expect(verify_response.body).to include '<meta property="og:site_name" content="Xikolo">'
    end

    it 'contains the Twitter Card meta tags' do
      expect(verify_response.body).to include '<meta name="twitter:card" content="summary">'
      expect(verify_response.body).to include "<meta name=\"twitter:title\" content=\"Certificate Details - #{course.title}\">"
      expect(verify_response.body).to include "<meta name=\"twitter:description\" content=\"Xikolo verifies that the candidate completed the course #{course.title} and passed the necessary exercises and exams to earn a course certificate.\">"
    end

    context 'with Open Badge' do
      let(:open_badge) { create(:open_badge, record:, open_badge_template: template) }
      let(:file_url) { "https://s3.xikolo.de/xikolo-certificate/openbadges/#{UUID4(user.id).to_s(format: :base62)}/#{UUID4(record.id).to_s(format: :base62)}.png" }

      before do
        stub_request(:get, open_badge.open_badge_template.file_uri.gsub('s3://', 'https://s3.xikolo.de/'))
          .with(query: hash_including({}))
          .to_return(body: File.new('spec/support/files/certificate/badge_template.png'), status: 200)
        stub_request(:put, file_url)
      end

      it 'links the Open Badge in Open Graph meta data' do
        expect(verify_response.body).to include "<meta property=\"og:image\" content=\"#{file_url}\">"
        expect(verify_response.body).to include "<meta property=\"og:image:secure_url\" content=\"#{file_url}\">"
      end

      it 'links the Open Badge in the Twitter Card' do
        expect(verify_response.body).to include "<meta name=\"twitter:image\" content=\"#{file_url}\">"
        expect(verify_response.body).to include "<meta name=\"twitter:image:alt\" content=\"Open Badge for #{course.title}\">"
      end
    end
  end
end
