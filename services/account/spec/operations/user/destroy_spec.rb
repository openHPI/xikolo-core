# frozen_string_literal: true

require 'spec_helper'

describe User::Destroy, type: :operation do
  subject(:operation) { described_class.new }

  let(:user) { create(:user) }
  let(:uid)  { UUID4(user.id).to_s(format: :base62) }

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

    create_list(:email, 3, user:)

    create(:session, user:)
    create(:authorization, user:)
    create(:custom_field_value, context: user)
    create(:password_reset, user:)
    create(:token, user:)
  end

  describe '#call' do
    subject(:call) { operation.call(user) }

    it { expect { call }.to change(user, :archived).to(true) }
    it { expect { call }.to change(user, :confirmed).to(false) }
    it { expect { call }.to change(user, :full_name).to('Deleted User') }
    it { expect { call }.to change(user, :display_name).to('Deleted User') }

    it 'removes all email addresses' do
      expect { call }.to change { user.emails.count }.from(4).to(0)
    end

    it 'removes all authorizations' do
      expect { call }.to change { user.authorizations.count }.from(1).to(0)
    end

    it 'removes all sessions' do
      expect { call }.to change { user.sessions.count }.from(1).to(0)
    end

    it 'removes all password resets' do
      expect { call }.to change { user.password_resets.count }.from(1).to(0)
    end

    it 'removes all user tokens' do
      expect { call }.to change { Token.where(user:).count }.from(1).to(0)
    end

    it 'removes all custom field values' do
      expect { call }.to change(CustomFieldValue, :count).from(1).to(0)
    end
  end
end
