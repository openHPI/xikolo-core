# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmation', type: :system do
  before do
    Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
      .and_return Stub.json([])

    Stub.request(:account, :post, '/sessions')
      .to_return Stub.json({
        errors: {ident: ['unconfirmed_user']},
      }, status: 422)

    Stub.request(:account, :get, '/emails/admin@xikolo.de')
      .to_return Stub.json({
        id: '57c2132c-03e8-4157-813f-72d3e7838fd8',
        user_id: 'de8242a9-41a2-42ee-9a57-9bb70b78d1a7',
        address: 'admin@xikolo.de',
      }, status: 200)
  end

  context 'with native login enabled' do
    let(:anonymous_session) do
      super().merge(features: {'account.login' => true})
    end

    it 'requests a new confirmation email' do
      visit '/'

      click_on 'Log in'
      fill_in 'E-mail', with: 'admin@xikolo.de'
      fill_in 'Password', with: 'secret'
      within '#login-form' do
        click_on 'Log in'
      end

      expect(page).to have_content 'This e-mail address has not been confirmed yet.'
      click_on 'here'
      expect(page).to have_content 'We re-sent you a confirmation e-mail.'
    end
  end
end
