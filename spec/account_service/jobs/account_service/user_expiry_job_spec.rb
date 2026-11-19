# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::UserExpiryJob, type: :job do
  subject(:perform) do
    described_class.new.perform(threshold.to_s)
  end

  let(:threshold) { 3.years.ago.to_date }
  let!(:old_user) { create(:'account_service/user', :unconfirmed, display_name: 'old user', last_access: (threshold - 1.day).to_date) }
  let(:uid) { UUID4(old_user.id).to_str(format: :base62) }

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

    stub_request(:delete, "#{ENV.fetch('CODE_OCEAN_API_URL', nil)}/api/internal/users/#{old_user.id}")
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => "Bearer #{ENV.fetch('XIKOLO_WEB_API')}",
        }
      ).to_return(status: 200, body: '', headers: {})

    create(:'account_service/user', :unconfirmed, display_name: 'unconfirmed user', created_at: 2.days.ago, last_access: nil) # This user should not be deleted, because it has never been active. (last_access is nil)
    create(:'account_service/user', display_name: 'new user', last_access: nil) # This user should not be deleted, because it has never been active. (last_access is nil)
    create(:'account_service/user', display_name: 'inactive user', created_at: 4.years.ago, last_access: threshold) # This user should not be deleted, because it has accessed the platform at the threshold date.
    create(:'account_service/user', :archived, display_name: 'archived user', created_at: 20.days.ago, last_access: 2.weeks.ago.to_date) # This user should not be deleted, because it is already archived.
  end

  it 'deletes non-archived user accounts with no activity after the threshold' do
    perform
    perform_enqueued_jobs do
      AccountService::UserDestroyJob.new(old_user.id, threshold.to_s).perform_now
    end

    expect(old_user.reload).to be_archived
    expect(old_user.display_name).to eq 'Deleted User'
  end
end
