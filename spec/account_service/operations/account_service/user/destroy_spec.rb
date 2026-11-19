# frozen_string_literal: true

require 'spec_helper'

describe AccountService::User::Destroy, type: :operation do
  subject(:operation) { described_class.new }

  let(:user_id) { SecureRandom.uuid }
  let(:user) { create(:'account_service/user', id: user_id, avatar_uri: "s3://xikolo-public/avatars/#{uid}/user_avatar.jpg") }
  let(:uid)  { UUID4(user_id).to_s(format: :base62) }

  let(:s3_user_avatar_delete) do
    stub_request(:delete,
      "#{test_s3_host}/xikolo-public/avatars/#{uid}/user_avatar.jpg")
  end

  before do
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
            <Contents>
              <Key>avatars/#{uid}/user_avatar.jpg</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML

    create_list(:'account_service/email', 3, user:)

    create(:'account_service/session', user:)
    create(:'account_service/authorization', user:)
    create(:'account_service/password_reset', user:)
    create(:'account_service/token', user:)
    s3_user_avatar_delete
    user.reload
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
      expect { call }.to change { AccountService::Token.where(user:).count }.from(1).to(0)
    end

    it 'deletes the user avatar from S3' do
      call
      expect(s3_user_avatar_delete).to have_been_requested
    end

    it 'enqueues the CodeOceanUserDeletionJob if the API key is present' do
      expect { call }.to have_enqueued_job(AccountService::CodeOceanUserDeletionJob).with(user.id)
    end
  end

  context 'with an associated teacher record' do
    let(:teacher_id) { SecureRandom.uuid }
    let(:tid) { UUID4(teacher_id).to_s(format: :base62) }
    let(:teacher) {
      create(:'course_service/teacher',
        user_id: user.id,
        id: teacher_id,
        name: 'New Teacher',
        description: {'de' => 'Neue Lehrer Beschreibung', 'en' => 'New teacher description'},
        picture_uri: "s3://xikolo-public/avatars/#{tid}/teacher_picture.jpg")
    }

    let(:s3_teacher_avatar_delete) do
      stub_request(:delete,
        "#{test_s3_host}/xikolo-public/avatars/#{tid}/teacher_picture.jpg")
    end

    before do
      teacher
      stub_request(:get,
        "#{test_s3_host}/xikolo-public?list-type=2&" \
        "prefix=avatars%2F#{tid}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-public</Name>
              <Prefix>avatars/#{tid}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>avatars/#{tid}/teacher_picture.jpg</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML

      s3_teacher_avatar_delete
    end

    describe '#call' do
      subject(:call) { operation.call(user) }

      it 'anonymizes the associated teacher record' do
        call
        expect(teacher.reload.name).to eq('Anonymized Teacher')
        expect(teacher.reload.description).to eq({'de' => 'Anonymisierter Lehrer', 'en' => 'Anonymized teacher'})
        expect(teacher.reload.picture_uri).to be_nil
      end

      it 'deletes the teacher avatar from S3' do
        call
        expect(s3_teacher_avatar_delete).to have_been_requested
      end
    end
  end
end
