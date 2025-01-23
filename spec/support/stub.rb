# frozen_string_literal: true

def stub_url(service, path)
  Addressable::URI.parse(Xikolo::Common::API.services[service]).join(path)
end

def api_stub_user(**)
  real_stub_user(stub_session_id, **)
end

##
# Stub service calls for authenticated requests in request specs.
#
def stub_user_request(**)
  real_stub_user(stub_session_id, id: SecureRandom.uuid, **).tap do |user|
    # TEMPORARY: Until the admin menu is fixed, the permissions for the root
    # context are requested again
    Stub.request(
      :account, :get, "/users/#{user[:id]}/permissions",
      query: {context: 'root', user_id: user[:id]}
    ).to_return Stub.json([])

    # For header authentication, a new session is created to remember the user
    Stub.request(
      :account, :post, '/sessions',
      body: {user: user[:id]}
    ).to_return Stub.json({
      id: SecureRandom.uuid,
    })
  end
end

def real_stub_user(session_id, **opts)
  permissions = opts.delete(:permissions) || []
  features = opts.delete(:features) || {}
  interrupts = opts.delete(:interrupts) || []
  masqueraded = opts.delete(:masqueraded) || false

  context_id = opts.delete(:context_id) || nil

  # Populate with default attributes
  user_attributes = Xikolo::Account::User.attributes.merge(
    anonymous: false,
    language: I18n.locale,
    preferred_language: I18n.locale
  ).merge(opts)

  user_attributes[:preferences_url] = "/users/#{user_attributes[:id]}/preferences"
  user_attributes[:permissions_url] = stub_url(:account, "/users/#{user_attributes[:id]}/permissions?user_id=#{user_attributes[:id]}")
  user_attributes[:consents_url] = stub_url(:account, "/users/#{user_attributes[:id]}/consents")

  Stub.request(
    :account, :get, "/sessions/#{session_id}",
    query: {embed: 'user,permissions,features', context: context_id || request_context_id}
  ).to_return Stub.json({
    id: session_id,
    user_id: user_attributes[:id],
    user: user_attributes,
    features:,
    permissions:,
    interrupts:,
    masqueraded:,
  })

  user_attributes
end

def stub_session_id
  'fb66ca82-5206-42fd-961b-4a8721fba975'
end

module StubAnonymousSession
  extend ActiveSupport::Concern

  included do
    before { Stub.service(:account, build(:'account:root')) }

    let(:anonymous_session) do
      {
        id: nil,
        masqueraded: false,
        user_id: '51f544b6-a9c7-4bfe-b76b-43a4441d36c3',
        features: {},
        permissions: [],
        interrupts: [],
        user: {
          anonymous: true,
          language: I18n.locale,
          preferred_language: I18n.locale,
        },
      }
    end
    let(:course_context_id) { 'bf971dd3-0e2f-4c73-a770-3b8718cdd95c' }
    let(:request_context_id) { 'root' }
    let!(:stub_anonymous_session) do
      Stub.request(
        :account, :get, '/sessions/anonymous',
        query: {embed: 'user,permissions,features', context: request_context_id}
      ).to_return Stub.json(anonymous_session)
    end
  end
end

module SetUserForControllerSpecs
  def stub_user(**)
    session[:id] = stub_session_id
    stub_user_request(**)
  end
end

module SetUserForSystemSpecs
  def stub_user(**)
    page.visit('/__session__')
    page.fill_in('session_id', with: stub_session_id)
    page.click_on('Save')
    page.has_content?('Session ID changed')

    stub_user_request(**)
  end
end

RSpec.configure do |config|
  config.include StubAnonymousSession

  config.include SetUserForControllerSpecs, type: :controller
  config.include SetUserForSystemSpecs, type: :system
end
