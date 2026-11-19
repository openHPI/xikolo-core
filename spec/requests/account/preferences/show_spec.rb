# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Preferences: Show', type: :request do
  subject(:show_preferences) { get '/preferences' }

  let(:user) { create(:'account_service/user') }
  let(:page) { Capybara::Node::Simple.new(response.body) }

  context 'for anonymous users' do
    it 'redirects to login' do
      show_preferences
      expect(response).to redirect_to new_session_path
    end
  end

  context 'for logged-in users' do
    let(:user) { create(:'account_service/user') }

    before do
      sign_in(user:)
    end

    context 'when the user has no pinboard subscriptions' do
      it 'shows the empty state' do
        show_preferences
        expect(page).to have_text('There are no discussion topics you are following.')
      end
    end

    context 'when the user has pinboard subscriptions' do
      let!(:subscription) { create(:'pinboard_service/subscription', user_id: user.id) }

      it 'lists the subscriptions' do
        show_preferences
        expect(page).to have_no_text('There are no discussion topics you are following.')
        expect(page).to have_text(subscription.question.title)
        expect(page).to have_link('Unfollow')
      end
    end
  end
end
