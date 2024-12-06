# frozen_string_literal: true

require 'spec_helper'

describe 'Delete user', type: :request do
  subject(:response) { request.value! }

  let(:api)     { Restify.new(:test).get.value! }
  let(:request) { api.rel(:user).delete(params) }

  let(:params) { {id: record.id} }
  let(:record) { create(:user, avatar_uri: 's3://xikolo-public/avatars/1.png') }
  let(:uid)    { UUID4(record.id).to_str(format: :base62) }

  let(:s3_avatar_index) do
    stub_request(:get,
      'http://s3.xikolo.de/xikolo-public?list-type=2&' \
      "prefix=avatars%2F#{uid}") \
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-public</Name>
            <Prefix>avatars/#{uid}</Prefix>
            <IsTruncated>false</IsTruncated>
          </ListBucketResult>
        XML
  end

  before do
    s3_avatar_index

    create_list(:email, 3, user: record)

    create(:session, user: record)

    # Ensure authorization has a provider that does have an implementation
    create(:authorization, user: record, provider: :saml)
  end

  it { is_expected.to respond_with :ok }

  describe 'response' do
    it 'responds with archived user resource' do
      expect(response.data).to include(
        'affiliated' => false,
        'avatar_url' => nil,
        'confirmed' => false,
        'display_name' => 'Deleted User',
        'email' => nil,
        'full_name' => 'Deleted User',
        'name' => 'Deleted User'
      )
    end
  end

  describe 'record' do
    subject(:action) { request.value! }

    let(:attributes) { -> { record.reload.attributes } }

    it 'archives the user record' do
      expect { action }.to change(&attributes).to include(
        'archived' => true
      )
    end

    it 'resets user names to placeholder values' do
      expect { action }.to change(&attributes).to include(
        'full_name' => 'Deleted User',
        'display_name' => 'Deleted User'
      )
    end

    it 'removes user confirmation' do
      expect { action }.to change(&attributes).to include(
        'confirmed' => false
      )
    end

    it 'removes all email addresses' do
      # There are 5 email addresses created:
      # one that is added in the create user factory
      # 3 in the create_list factory in the before
      # block, and an additional email address from the authorization
      expect { action }.to change {
        record.emails.reload.count
      }.from(5).to(0)
    end

    it 'removes all authorizations' do
      expect { action }.to change {
        record.authorizations.reload.count
      }.from(1).to(0)
    end

    it 'removes all sessions' do
      expect { action }.to change {
        record.sessions.reload.count
      }.from(1).to(0)
    end
  end

  describe 'avatar' do
    let(:s3_avatar_index) do
      body = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>xikolo-public</Name>
          <Prefix>avatars/#{uid}</Prefix>
          <IsTruncated>false</IsTruncated>
          <Contents>
            <Key>avatars/#{uid}/avatar_v1.jpg</Key>
            <LastModified>2018-08-02T13:27:56.768Z</LastModified>
            <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
          </Contents>
          <Contents>
            <Key>avatars/#{uid}/avatar_v2.png</Key>
            <LastModified>2018-09-02T13:43:56.768Z</LastModified>
            <ETag>&#34;d41d8cd98f00ak34ad800998ecf8427e&#34;</ETag>
          </Contents>
        </ListBucketResult>
      XML

      stub_request(:get, 'http://s3.xikolo.de/xikolo-public')
        .with(
          query: {'list-type': 2, prefix: "avatars/#{uid}"}
        )
        .to_return(
          status: 200,
          body:,
          headers: {
            'Content-Type' => 'Content-Type: application/xml',
          }
        )
    end

    let!(:s3_avatar_delete_1) do
      stub_request(:delete,
        "http://s3.xikolo.de/xikolo-public/avatars/#{uid}/avatar_v1.jpg")
    end

    let!(:s3_avatar_delete_2) do
      stub_request(:delete,
        "http://s3.xikolo.de/xikolo-public/avatars/#{uid}/avatar_v2.png")
    end

    it 'removes the current avatar image' do
      request.value!
      expect(s3_avatar_delete_2).to have_been_requested
    end

    it 'removes leftover previous avatar images' do
      request.value!
      expect(s3_avatar_delete_1).to have_been_requested
    end
  end
end
