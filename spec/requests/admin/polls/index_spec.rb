# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Polls: Index', type: :request do
  subject(:action) { get('/admin/polls', headers:) }

  let(:headers) { {} }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { %w[helpdesk.polls.manage] }

      before do
        create(:poll, :current,
          question: 'What do you think about our platform?',
          start_at: Date.new(2022, 1, 1))
      end

      it 'lists all existing polls' do
        action
        expect(response).to render_template :index
        expect(response.body).to include 'What do you think about our platform?'
        expect(response.body).to include 'Jan 01, 2022'
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects to the homepage' do
        action
        expect(response).to redirect_to root_path
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the login page' do
      action
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
