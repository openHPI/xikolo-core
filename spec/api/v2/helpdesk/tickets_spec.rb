# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::Helpdesk::Tickets do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:env) do
    {
      'HTTP_ACCEPT' => 'application/json',
      'CONTENT_TYPE' => 'application/vnd.api+json',
    }
  end

  describe 'POST tickets' do
    subject(:creation) { post '/v2/tickets', payload.to_json, env }

    let(:payload) do
      {
        data: {
          type: 'tickets',
          id: nil,
          attributes: {
            title: 'Help me',
            report: 'I cannot learn',
            topic: 'technical',
            language: 'en',
            mail: 'guest@example.com',
            url: '',
            data: 'ANDROID',
          },
        },
      }
    end

    it 'stores the ticket' do
      expect { creation }.to change(Helpdesk::Ticket, :count).from(0).to(1)
      expect(creation).to be_successful

      expect(Helpdesk::Ticket.first).to have_attributes(
        title: 'Help me',
        user_id: nil,
        mail: 'guest@example.com'
      )
    end

    it '(asynchronously) sends an email to the helpdesk system' do
      expect { creation }.to have_enqueued_mail(Helpdesk::TicketMailer, :new_ticket_email)
    end

    context 'as a registered user' do
      before { api_stub_user id: user_id, email: 'registered@example.com' }

      let(:user_id) { generate(:user_id) }
      let(:env) do
        super().merge('rack.session' => {id: stub_session_id})
      end

      it 'creates the ticket, assigns it to the user and uses their email address' do
        expect { creation }.to change(Helpdesk::Ticket, :count).from(0).to(1)
        expect(creation).to be_successful

        expect(Helpdesk::Ticket.first).to have_attributes(
          title: 'Help me',
          user_id:,
          mail: 'registered@example.com'
        )
      end
    end

    describe '(data)' do
      subject(:json) { JSON.parse(creation.body)['data'] }

      it 'returns the stored attributes' do
        expect(json['attributes']).to include({
          'title' => 'Help me',
          'report' => 'I cannot learn',
          'mail' => 'guest@example.com',
        })
      end
    end

    context 'without title' do
      let(:payload) do
        super().tap do |p|
          p[:data][:attributes][:title] = ''
        end
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(creation.status).to eq 422
      end

      it 'does not send out any email' do
        expect { creation }.not_to have_enqueued_mail
      end
    end
  end
end
