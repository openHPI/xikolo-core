# frozen_string_literal: true

require 'spec_helper'

describe 'User\'s avatar upload', type: :request do
  subject(:update_avatar) { api.rel(:user).patch(data, params: {id: user.id}).value! }

  let(:user) { create(:'account_service/user') }
  let(:data) { {} }
  let(:api) { Restify.new(account_service_url).get.value! }

  describe '(S3 avatar upload)' do
    shared_examples 'does not update the avatar' do |error_details|
      it 'does not update the avatar url of the user' do
        expect { update_avatar }.to raise_error(Restify::ClientError)
        expect(user.reload.avatar_url).to eq old_store_stub_url
      end

      it 'raises an unprocessable entity error' do
        expect { update_avatar }.to raise_error(Restify::UnprocessableEntity) do |error|
          expect(error.errors).to eq error_details
        end
      end
    end

    shared_examples 'updates the avatar' do
      let!(:store_stub) do
        stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>')
      end

      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
      end

      it { is_expected.to respond_with :ok }

      it 'instructs S3 to move the file to the correct bucket' do
        update_avatar
        expect(store_stub).to have_been_requested
      end

      it 'updates the avatar url referencing the file in the new bucket' do
        expect { update_avatar }.to change { user.reload.avatar_url }
          .from(old_store_stub_url)
          .to match store_stub_url
      end
    end

    let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
    let(:file_url) do
      "http://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/profil.jpg"
    end

    before do
      stub_request(:get,
        'http://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}")
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
                <Key>uploads/f13d30d3-6369-4816-9695-af5318c8ac15/profil.jpg</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
    end

    context 'user with new (not existing) avatar' do
      let(:store_stub_url) { %r{http://s3\.xikolo\.de/xikolo-public/avatars/[0-9A-Za-z]+/[0-9A-Za-z]+/profil\.jpg} }
      let(:store_stub) do
        stub_request(:put, store_stub_url).to_return(status: 200)
      end
      let(:old_store_stub_url) { nil }

      context 'with avatar_upload_id' do
        let(:data) { {avatar_upload_id: upload_id} }

        context 'when upload is successful' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
          end

          it_behaves_like 'updates the avatar'
        end

        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          error_details = {'avatar_upload_id' => ['invalid upload']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          error_details = {'avatar_upload_id' => ['could not process file upload']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'image/jpeg',
                'Content-Length' => '1000',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, store_stub_url).to_return(status: 403)
          end

          error_details = {'avatar_upload_id' => ['could not process file upload']}
          it_behaves_like 'does not update the avatar', error_details
        end
      end

      context 'with avatar_uri' do
        let(:data) do
          {
            avatar_upload_id: upload_id,
            avatar_uri: "upload://#{upload_id}/profil.jpg",
          }
        end
        let(:store_stub_url) { %r{http://s3\.xikolo\.de/xikolo-public/avatars/[0-9A-Za-z]+/profil\.jpg} }

        before do
          stub_request(:head, store_stub_url)
            .to_return(status: 200)
          stub_request(:head, store_stub_url).and_return(status: 404)
          stub_request(:put, store_stub_url)
            .to_return(status: 200, body: '<xml></xml>')
        end

        context 'when upload is successful' do
          it_behaves_like 'updates the avatar'
        end

        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          error_details = {'avatar_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          error_details = {'avatar_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, store_stub_url).to_return(status: 403)
          end

          error_details = {'avatar_uri' => ['Could not save file - access to destination is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end
      end
    end

    context 'with existing avatar' do
      let(:old_avatar_uri) { 's3://xikolo-public/avatars/3/avatar_v1.jpg' }
      let(:user) { create(:'account_service/user', avatar_uri: old_avatar_uri) }
      let(:store_stub_url) { %r{http://s3\.xikolo\.de/xikolo-public/avatars/[0-9A-Za-z]+/[0-9A-Za-z]+/profil\.jpg} }
      let(:old_store_stub_url) { 'http://s3.xikolo.de/xikolo-public/avatars/3/avatar_v1.jpg' }

      before do
        stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>')

        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
      end

      context 'with upload_id' do
        let(:data) { {avatar_upload_id: upload_id} }
        let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
        let(:file_url) do
          "http://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/profil.jpg"
        end

        context 'when upload is successful' do
          it_behaves_like 'updates the avatar'
          it 'schedules the removal of the old avatar image' do
            expect { update_avatar }.to have_enqueued_job(AccountService::FileDeletionJob).with(old_avatar_uri)
          end
        end

        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          error_details = {'avatar_upload_id' => ['invalid upload']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          error_details = {'avatar_upload_id' => ['could not process file upload']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, store_stub_url).to_return(status: 403)
          end

          error_details = {'avatar_upload_id' => ['could not process file upload']}
          it_behaves_like 'does not update the avatar', error_details
        end
      end

      context 'with avatar_uri' do
        let(:store_stub_url) { %r{http://s3\.xikolo\.de/xikolo-public/avatars/[0-9A-Za-z]+/profil\.jpg} }
        let(:data) { {avatar_upload_id: upload_id, avatar_uri: "upload://#{upload_id}/profil.jpg"} }

        before do
          stub_request(:head, store_stub_url).and_return(status: 404)
        end

        context 'when upload is successful' do
          it_behaves_like 'updates the avatar'
          it 'schedules the removal of the old avatar image' do
            expect { update_avatar }.to have_enqueued_job(AccountService::FileDeletionJob).with(old_avatar_uri)
          end
        end

        context 'when upload was rejected' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'rejected',
              }
            )
          end

          error_details = {'avatar_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'without access permission' do
          before do
            stub_request(:head, file_url).to_return(status: 403)
          end

          error_details = {'avatar_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end

        context 'when saving to destination is forbidden' do
          before do
            stub_request(:head, file_url).to_return(
              status: 200,
              headers: {
                'Content-Type' => 'inode/x-empty',
                'X-Amz-Meta-Xikolo-Purpose' => 'account_user_avatar',
                'X-Amz-Meta-Xikolo-State' => 'accepted',
              }
            )
            stub_request(:put, store_stub_url).to_return(status: 403)
          end

          error_details = {'avatar_uri' => ['Could not save file - access to destination is forbidden.']}
          it_behaves_like 'does not update the avatar', error_details
        end
      end

      context 'passing nil as avatar_uri' do
        let(:data) { {avatar_uri: nil} }

        it 'deletes the existing avatar' do
          expect { update_avatar }.to change { user.reload.avatar_url }
            .from(old_store_stub_url)
            .to(nil)
        end

        it 'schedules the removal of the old avatar image' do
          expect { update_avatar }.to have_enqueued_job(AccountService::FileDeletionJob).with(old_avatar_uri)
        end
      end
    end
  end

  describe '(external avatar URL)' do
    let(:data) do
      {avatar_uri: 'http://external.example.com/profil.jpg'}
    end
    let(:json) { JSON.parse update_avatar.response.body }

    it 'stores and responds with the external avatar URL' do
      expect(json).to include('avatar_url' => data[:avatar_uri])
    end

    describe 'remove avatar' do
      let(:user) { create(:'account_service/user', avatar_uri: 'https://external.example.com/profil.jpg') }
      let(:data) { super().merge(avatar_uri: nil) }

      it 'removes the external avatar URL of the user' do
        expect(json['avatar_url']).to be_nil
        expect(user.reload.avatar_uri).to be_nil
      end
    end
  end
end
