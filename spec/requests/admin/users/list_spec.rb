# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Users: Index', type: :request do
  subject(:request) { get users_path, params: }

  let(:params) { {} }
  let(:page) { Capybara.string(response.body) }

  context 'as anonymous user' do
    it 'redirects the user' do
      request
      expect(response).to have_http_status :see_other
    end
  end

  context 'as logged in user without permission' do
    let(:user) { create(:'account_service/user') }

    before { sign_in(user:) }

    it 'redirects the user' do
      request
      expect(response).to have_http_status :see_other
    end
  end

  context 'as user with permission' do
    let(:user) { create(:'account_service/user') }

    before do
      role = create(:'account_service/role', permissions: ['account.user.index'])
      create(:'account_service/grant', principal: user, role:)

      sign_in(user: user)
    end

    it 'offers all user status filters' do
      request

      expect(page).to have_select 'Status', options: ['All', 'Banned', 'Confirmed', 'Unconfirmed', 'Top talent']
    end

    context 'when filtering by status' do
      let(:params) { {status: 'banned'} }

      it 'keeps the selected status and offers a reset link' do
        request

        expect(page).to have_select 'Status', selected: 'Banned'
        expect(page).to have_link 'Reset all filters', href: users_path
      end
    end

    context 'with users' do
      let!(:spongebob) { create(:'account_service/user', full_name: 'SpongeBob SquarePants') }
      let!(:patrick) { create(:'account_service/user', :banned, full_name: 'Patrick Star') }
      let!(:squidward) { create(:'account_service/user', :unconfirmed, full_name: 'Squidward Tentacles') }
      let!(:plankton) { create(:'account_service/user', :archived, full_name: 'Plankton') }

      it 'lists only non-archived users' do
        request
        expect(response).to have_http_status :ok
        expect(page).to have_text spongebob.full_name
        expect(page).to have_text patrick.full_name
        expect(page).to have_text squidward.full_name
        expect(page).to have_no_text plankton.full_name
      end

      it 'shows status badges for confirmed, unconfirmed, and banned users' do
        request
        expect(page).to have_css('.x-badge-success', text: 'Confirmed')
        expect(page).to have_css('.x-badge-warning', text: 'Unconfirmed')
        expect(page).to have_css('.x-badge-error', text: 'Banned')
      end
    end

    context 'when filtering by name or email' do
      let!(:spongebob) { create(:'account_service/user', full_name: 'SpongeBob SquarePants') }
      let!(:patrick) { create(:'account_service/user', full_name: 'Patrick Star') }

      it 'returns matching users' do
        get users_path(q: 'SpongeBob')
        expect(response).to have_http_status :ok
        expect(page).to have_field 'Search', with: 'SpongeBob'
        expect(page).to have_text spongebob.full_name
        expect(page).to have_no_text patrick.full_name
      end

      it 'shows no results state when nothing matches' do
        get users_path(q: 'nonexistent')

        expect(response).to have_http_status :ok
        expect(page).to have_text "Sorry, we couldn't find any matching entry."
      end

      it 'shows a reset filter link when a query is active' do
        get users_path(q: 'SpongeBob')

        expect(page).to have_link 'Reset all filters', href: users_path
      end

      it 'does not show a reset filter link without a query' do
        request
        expect(page).to have_no_link 'Reset all filters'
      end
    end
  end
end
