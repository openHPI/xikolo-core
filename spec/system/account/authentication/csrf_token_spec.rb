# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Authentication: CRSF Token', type: :system do
  around(&With(:csrf_protection, true))

  context 'with empty / cleared session' do
    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(:course, :get, '/api/v2/course/courses', query: hash_including({}))
        .and_return Stub.json([])
    end

    let(:anonymous_session) do
      super().merge(features: {'account.login' => true})
    end

    it 'shows error message on login form' do
      visit '/'

      click_on 'Log in'
      fill_in 'E-mail', with: 'admin@xikolo.de'
      fill_in 'Password', with: 'secret'

      page.driver.browser.manage.delete_all_cookies

      find_by_id('login-form').click_on 'Log in'

      expect(page).to have_field 'E-mail'
      expect(page).to have_field 'Password'

      expect(page).to have_content \
        'Your session has expired. Please log in again.'
    end
  end
end
