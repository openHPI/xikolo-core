# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Polls: Update', type: :request do
  subject(:update_poll) { patch "/admin/polls/#{poll.id}", params: {poll: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[helpdesk.polls.manage] }
  let(:poll) { create(:poll, :current, question: 'What?') }
  let(:params) { attributes_for(:poll).merge(question: 'What do you think?') }

  before { stub_user_request permissions: }

  it 'updates the poll and redirects to the polls list' do
    expect { update_poll }.to change { poll.reload.question }
      .from('What?')
      .to('What do you think?')
    expect(response).to redirect_to admin_polls_path
    expect(flash[:success].first).to eq 'The poll has been updated.'
  end

  context 'without question' do
    let(:params) { super().merge question: ' ' }

    it 'displays an error message' do
      expect { update_poll }.not_to change { poll.reload.question }
      expect(response.body).to render_template :edit
      expect(flash[:error].first).to eq 'The poll has not been updated.'
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      update_poll
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      update_poll
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
