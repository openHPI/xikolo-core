# frozen_string_literal: true

def stub_url(service, path)
  Addressable::URI.parse("#{Xikolo::Common::API.services[service]}/#{path}".gsub('//', '/'))
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

  user_attributes[:preferences_url] = "/account_service/users/#{user_attributes[:id]}/preferences"
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

def stub_file_upload(upload_id:, filename:, purpose:, bucket:, state: 'accepted')
  # Get the file from the generic upload bucket
  stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads/#{upload_id}")
    .to_return(
      status: 200,
      headers: {'Content-Type' => 'Content-Type: application/xml'},
      body: <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>xikolo-uploads</Name>
          <Prefix>uploads/#{upload_id}</Prefix>
          <IsTruncated>false</IsTruncated>
          <Contents>
            <Key>uploads/#{upload_id}/#{filename}</Key>
            <LastModified>2018-08-02T13:27:56.768Z</LastModified>
            <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
          </Contents>
        </ListBucketResult>
      XML

  # For checking the validity of the upload (probably only necessary for uploading via SingleFileUpload)
  stub_request(:head, "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{filename}").to_return(
    status: 200,
    headers: {
      'Content-Type' => 'inode/x-empty',
      'X-Amz-Meta-Xikolo-Purpose' => purpose,
      'X-Amz-Meta-Xikolo-State' => state,
    }
  )

  # Move the file to the target bucket
  stub_request(:put, %r{https://s3.xikolo.de/#{bucket}/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{filename}})
    .to_return(status: 200, body: '<xml></xml>')
end

module StubAnonymousSession
  extend ActiveSupport::Concern

  included do
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

    # Wait for page load
    page.find('html')

    page.fill_in('session_id', with: stub_session_id)
    page.click_on('Save')

    begin
      # Ensure session change did work
      expect(page).to have_content('Session ID changed')
    rescue Selenium::WebDriver::Error::UnknownError => e
      # Retry on stale node ids on page changes:
      #
      #    Selenium::WebDriver::Error::UnknownError: unknown error: unhandled inspector error: {"code":-32000,"message":"Node with given id does not belong to the document"}
      #      (Session info: chrome=133.0.6943.141)
      retry if e.message.include?('Node with given id does not belong to the document')
    end

    stub_user_request(**)
  end
end

RSpec.configure do |config|
  config.include StubAnonymousSession

  config.include SetUserForControllerSpecs, type: :controller
  config.include SetUserForSystemSpecs, type: :system
end
