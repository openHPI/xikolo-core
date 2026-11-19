# frozen_string_literal: true

def stub_url(service, path)
  Addressable::URI.parse("#{Xikolo::Common::API.services[service]}/#{path}".gsub('//', '/'))
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
  AccountService::User.anonymous.id
end

def stub_file_upload(upload_id:, filename:, purpose:, bucket:, state: 'accepted')
  # Get the file from the generic upload bucket
  stub_request(:get, "#{test_s3_host}/xikolo-uploads?list-type=2&prefix=uploads/#{upload_id}")
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
  stub_request(:head, "#{test_s3_host}/xikolo-uploads/uploads/#{upload_id}/#{filename}").to_return(
    status: 200,
    headers: {
      'Content-Type' => 'inode/x-empty',
      'X-Amz-Meta-Xikolo-Purpose' => purpose,
      'X-Amz-Meta-Xikolo-State' => state,
    }
  )

  # Move the file to the target bucket
  stub_request(:put, %r{#{test_s3_host}/#{bucket}/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{filename}})
    .to_return(status: 200, body: '<xml></xml>')
end

module StubAnonymousSession
  extend ActiveSupport::Concern

  included do
    let(:course_context_id) { AccountService::Context.root.id }
    let(:request_context_id) { 'root' }
  end
end

RSpec.configure do |config|
  config.include StubAnonymousSession
end
