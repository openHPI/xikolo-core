# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Helpdesk: Create', type: :request do
  subject(:send_helpdesk) { post '/helpdesk', params: }

  let(:course) { build(:'course:course', id: generate(:course_id), title: 'First course') }
  let(:params) do
    {
      title: 'Test Ticket',
      mail: 'user@example.com',
      report: 'I have a problem',
      language: 'en',
      url: 'https://example.com/current/path',
    }
  end
  let(:page) { Capybara.string(response.body) }

  context 'anonymous user' do
    context 'technical question' do
      let(:params) { super().merge(category: 'technical') }

      it 'sets the params for the ticket correctly' do
        expect { send_helpdesk }.to change(Helpdesk::Ticket, :count).by(1)
        expect(Helpdesk::Ticket.first).to have_attributes(topic: 'technical', course_id: nil)
        expect(response).to have_http_status :ok
      end
    end

    context 'course-specific question' do
      let(:course_id) { generate(:course_id) }
      let(:params) { super().merge(category: course_id) }

      it 'sets the params for the ticket correctly' do
        expect { send_helpdesk }.to change(Helpdesk::Ticket, :count).by(1)
        expect(Helpdesk::Ticket.first).to have_attributes(topic: 'course', course_id:)
        expect(response).to have_http_status :ok
      end
    end

    context 'incorrect course ID parameter' do
      let(:params) { super().merge(category: '') }

      it 'assumes this is a technical question' do
        expect { send_helpdesk }.to change(Helpdesk::Ticket, :count).by(1)
        expect(Helpdesk::Ticket.first).to have_attributes(topic: 'technical', course_id: nil)
        expect(response).to have_http_status :ok
      end
    end
  end

  context 'with missing email address' do
    let(:params) do
      {
        title: 'Test Ticket',
        report: 'I have a problem',
        language: 'en',
        url: 'https://example.com/current/path',
      }
    end

    it 'does not create a ticket and returns unprocessable_entity' do
      expect { send_helpdesk }.not_to change(Helpdesk::Ticket, :count)
      expect(response).not_to be_successful
      expect(response).to have_http_status :unprocessable_entity
      expect(page).to have_content 'Oops something went wrong.'
    end
  end

  context 'with invalid title' do
    let(:params) do
      {
        title: "Test Ticket: #{'x' * 300}",
        mail: 'user@example.com',
        report: 'I have a problem',
        language: 'en',
        url: 'https://example.com/current/path',
      }
    end

    it 'does not create a ticket and returns unprocessable_entity' do
      expect { send_helpdesk }.not_to change(Helpdesk::Ticket, :count)
      expect(response).not_to be_successful
      expect(response).to have_http_status :unprocessable_entity
      expect(page).to have_content 'Oops something went wrong.'
    end
  end

  context 'with recaptcha enabled' do
    let(:recaptcha_score) { 0.5 }
    let(:secret_key_v2) { '6Ld08WIqAAAAAMmBrtQ1_InW6wu0WOlquOcR2GR6' }
    let(:secret_key_v3) { '6Lfz8GIqAAAAAI7luM866NJN5rdPx70hJDO2tsO3' }

    def stub_recaptcha_v3(success:)
      stub_recaptcha_response(:recaptcha_token_v3)
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(RecaptchaIntegration)
        .to receive(:verify_recaptcha)
        .with(hash_including(action: 'helpdesk', minimum_score: recaptcha_score, secret_key: secret_key_v3))
        .and_return(success)
    end

    def stub_recaptcha_v2(success:)
      stub_recaptcha_response(:recaptcha_token_v2)
      allow_any_instance_of(RecaptchaIntegration)
        .to receive(:verify_recaptcha)
        .with(hash_including(secret_key: secret_key_v2))
        .and_return(success)
    end

    def stub_recaptcha_response(type)
      allow_any_instance_of(RecaptchaIntegration)
        .to receive(type)
        .and_return(SecureRandom.uuid)
      # rubocop:enable RSpec/AnyInstance
    end

    before do
      xi_config <<~YML
        recaptcha:
          enabled: true
          score: #{recaptcha_score}
          site_key_v2: 6Ld08WIqAAAAAMzWokw1WbhB2oY0LJRABkYC0Wrz
          site_key_v3: 6Lfz8GIqAAAAADuPSE0XXDa9XawEf0upsswLgsBA
      YML
    end

    context 'with invisible recaptcha verification success (v3)' do
      before { stub_recaptcha_v3(success: true) }

      it 'allows creating a ticket' do
        expect { send_helpdesk }.to change(Helpdesk::Ticket, :count).by(1)
        expect(response).to have_http_status :ok
        expect(page).to have_content 'Your request has been sent to our support team'
      end
    end

    context 'with invisible recaptcha verification failure (v3)' do
      before do
        Stub.service(:course, build(:'course:root'))
        Stub.request(
          :course, :get, '/courses',
          query: hash_including(public: 'true', hidden: 'false')
        ).to_return Stub.json([course])

        stub_recaptcha_v3(success: false)
      end

      it 'prevents creating a ticket and re-renders the page with a checkbox recaptcha (v2)' do
        expect { send_helpdesk }.not_to change(Helpdesk::Ticket, :count)
        expect(response).to have_http_status :ok
        expect(page).to have_content "Confirm you're human by checking the box below."
      end

      context 'with checkbox recaptcha verification success (v2)' do
        before do
          stub_recaptcha_v3(success: false)
          stub_recaptcha_v2(success: true)
        end

        it 'allows ticket creation' do
          expect { send_helpdesk }.to change(Helpdesk::Ticket, :count).by(1)
          expect(response).to have_http_status :ok
          expect(page).to have_content 'Your request has been sent to our support team'
        end
      end
    end
  end
end
