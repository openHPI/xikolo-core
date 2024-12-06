# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Polls: Create', type: :request do
  subject(:create_poll) { post '/admin/polls', params: {poll: params}, headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[helpdesk.polls.manage] }
  let(:params) do
    {
      question: 'What do you think?',
      start_at: 1.day.ago,
      end_at: 1.week.from_now,
      allow_multiple_choices: true,
      show_intermediate_results: true,
    }
  end

  before { stub_user_request permissions: }

  it 'creates a new poll and redirects to the edit view' do
    expect { create_poll }.to change(Poll::Poll, :count).from(0).to(1)
    expect(response).to redirect_to edit_admin_poll_path(id: Poll::Poll.first.id)
    expect(flash[:success].first).to eq 'The poll has been created.'
  end

  context 'without question' do
    let(:params) { super().merge question: ' ' }

    it 'displays an error message' do
      expect { create_poll }.not_to change(Poll::Poll, :count).from(0)
      expect(response.body).to render_template :new
      expect(flash[:error].first).to eq 'The poll has not been created.'
    end
  end

  context 'with start date after end date' do
    let(:params) { super().merge start_at: 1.week.from_now, end_at: 2.days.from_now }

    it 'displays an error message' do
      expect { create_poll }.not_to change(Poll::Poll, :count).from(0)
      expect(response.body).to render_template :new
      expect(flash[:error].first).to eq 'The poll has not been created.'
      expect(response.body).to include 'The end date must be after the start date.'
    end
  end

  context 'without permissions' do
    let(:permissions) { [] }

    it 'redirects to the homepage' do
      create_poll
      expect(response).to redirect_to root_path
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      create_poll
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
