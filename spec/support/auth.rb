# frozen_string_literal: true

module RequestTestAuthHelper
  def sign_in(user: create(:'account_service/user'), password: attributes_for(:'account_service/user').fetch(:password))
    post sessions_path, params: {login: {email: user.email, password:}}
    user
  end
end

module ControllerTestAuthHelper
  def sign_in(user: create(:'account_service/user'), permissions: nil)
    if permissions
      role = create(:'account_service/role', permissions: Array(permissions))
      create(:'account_service/grant', principal: user, role:)
    end

    session[:id] = create(:'account_service/session', user:).id

    user
  end
end

module SystemTestAuthHelper
  def sign_in(user: create(:'account_service/user'), password: attributes_for(:'account_service/user').fetch(:password))
    visit '/'
    click_on('Log in')

    within '#login-form' do
      fill_in 'E-mail', with: user.primary_email.address
      fill_in 'Password', with: password

      click_on 'Log in'
    end

    unless has_content?('My upcoming learning opportunities')
      raise 'Auth helper sign error!'
    end

    user
  end

  def enroll_in(course)
    attempts = 0

    # Enrolling is flaky on CI
    begin
      visit "/learn/#{course.course_code}"
      click_on 'Enroll now'

      unless has_content?('You have been enrolled successfully.')
        raise 'Auth helper course enrollment error!'
      end
    rescue RuntimeError
      attempts += 1
      raise if attempts > 2

      retry
    end
  end
end

RSpec.configure do |config|
  config.include RequestTestAuthHelper, type: :request
  config.include ControllerTestAuthHelper, type: :controller
  config.include SystemTestAuthHelper, type: :system
end
