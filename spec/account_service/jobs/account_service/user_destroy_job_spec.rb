# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::UserDestroyJob, type: :job do
  subject(:perform) do
    described_class.new.perform(user.id, threshold)
  end

  let(:threshold) { nil }
  let!(:user) { create(:'account_service/user', :unconfirmed) }
  let(:uid) { UUID4(user.id).to_str(format: :base62) }

  let(:s3_avatar_index) do
    stub_request(:get,
      "#{test_s3_host}/xikolo-public?list-type=2&" \
      "prefix=avatars%2F#{uid}")
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

    stub_request(:delete, "#{ENV.fetch('CODE_OCEAN_API_URL', nil)}/api/internal/users/#{user.id}")
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => "Bearer #{ENV.fetch('XIKOLO_WEB_API')}",
        }
      ).to_return(status: 200, body: '', headers: {})
  end

  it 'calls User::Destroy for the user' do
    perform_enqueued_jobs do
      perform
    end

    expect(user.reload).to be_archived
    expect(user.reload.display_name).to eq 'Deleted User'
  end

  context 'with last access before threshold date' do
    let(:threshold) { '2024-07-26' }
    let!(:user) { create(:'account_service/user', :unconfirmed, last_access: '2024-07-25') }

    it 'destroy the user record' do
      perform_enqueued_jobs do
        perform
      end

      expect(user.reload).to be_archived
      expect(user.reload.display_name).to eq 'Deleted User'
    end
  end

  context 'with last access after threshold date' do
    let(:threshold) { '2024-07-26' }
    let(:user) { create(:'account_service/user', :unconfirmed, last_access: '2024-07-26') }

    it 'does not destroy the user record' do
      perform_enqueued_jobs do
        perform
      end

      expect(user.reload).not_to be_archived
      expect(user.reload.display_name).not_to eq 'Deleted User'
    end
  end

  context 'without last access and a threshold date given' do
    let(:threshold) { '2024-07-26' }
    let(:user) { create(:'account_service/user', :unconfirmed) }

    it 'does not destroy the user record' do
      perform_enqueued_jobs do
        perform
      end

      expect(user.reload).not_to be_archived
      expect(user.reload.display_name).not_to eq 'Deleted User'
    end
  end

  context 'with error while deleting' do
    it 'retries calling User::Destroy' do
      expect(AccountService::User::Destroy).to receive(:call).once.with(user).and_raise(RuntimeError)
      expect(AccountService::User::Destroy).to receive(:call).once.with(user)

      expect { perform }.to raise_error(RuntimeError)
      perform
    end
  end
end
