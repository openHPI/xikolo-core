# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Space: Files: Create', type: :request do
  subject(:create_file) do
    api.rel(:collab_space).get(id: collab_space.id).value
      .rel(:files).post(payload).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:collab_space) { create(:collab_space) }
  let(:payload) do
    {
      title: 'My file',
      description: 'My file description',
      creator_id: '00000001-3100-4444-9999-000000000001',
      upload_uri:,
    }
  end
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:upload_uri) { "upload://#{upload_id}/proposal.pdf" }
  let(:store_stub_url) do
    %r{https://s3.xikolo.de/xikolo-collabspace/collabspaces/[0-9a-zA-Z]+/files/[0-9a-zA-Z]+/[0-9a-zA-Z]+/proposal.pdf}x
  end

  context 'with missing params' do
    let(:payload) { super().merge(title: '') }

    it 'responds with 442 Unprocessable Content' do
      expect { create_file }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'title' => ['can\'t be blank']
      end
    end
  end

  context 'with valid upload' do
    before do
      stub_request(
        :head,
        "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/proposal.pdf"
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'collabspace_file',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 4096,
          'Content-Type' => 'application/pdf',
        }
      )
      stub_request(:head, store_stub_url).and_return(status: 404)
    end

    let!(:store_stub) do
      stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>')
    end

    it { is_expected.to respond_with :created }

    it 'creates a new file object' do
      expect { create_file }.to change(UploadedFile, :count).from(0).to(1)
    end

    it 'creates a corresponding file version object' do
      expect { create_file }.to change(FileVersion, :count).from(0).to(1)
    end

    it 'instructs S3 to move the file to the correct bucket' do
      create_file
      expect(store_stub).to have_been_requested
    end

    it 'updates the blob URI referencing the file in the new bucket' do
      expect(create_file['blob_url']).to match store_stub_url
    end

    it 'responds with file' do
      expect(create_file.keys).to match_array \
        %w[id title original_filename creator_id created_at size blob_url url]
    end

    it 'caches the file size' do
      create_file
      expect(UploadedFile.last.versions.first.size).to eq 4096
    end
  end

  context 'with rejected upload' do
    before do
      stub_request(
        :head,
        "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/proposal.pdf"
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'collabspace_file',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )
    end

    it 'does not create file objects' do
      expect { create_file }.to raise_error(Restify::UnprocessableEntity)
      expect(UploadedFile.count).to eq 0
      expect(FileVersion.count).to eq 0
    end

    context 'with existing file version' do
      before { create(:file, collab_space:, filename: 'proposal.pdf') }

      it 'does not change existing file objects' do
        expect { create_file }.to raise_error(Restify::UnprocessableEntity)
        expect(UploadedFile.count).to eq 1
        expect(FileVersion.count).to eq 1
      end
    end
  end

  context 'with storage errors (saving upload to bucket)' do
    before do
      stub_request(
        :head,
        "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/proposal.pdf"
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'collabspace_file',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 4096,
          'Content-Type' => 'application/pdf',
        }
      )
      stub_request(:head, store_stub_url).and_return(status: 404)
      stub_request(:put, store_stub_url).to_return(status: 503)
    end

    it 'does not create file objects' do
      expect { create_file }.to raise_error(Restify::UnprocessableEntity)
      expect(UploadedFile.count).to eq 0
      expect(FileVersion.count).to eq 0
    end

    context 'with existing file version' do
      before { create(:file, collab_space:, filename: 'proposal.pdf') }

      it 'does not change existing file objects' do
        expect { create_file }.to raise_error(Restify::UnprocessableEntity)
        expect(UploadedFile.count).to eq 1
        expect(FileVersion.count).to eq 1
      end
    end
  end
end
