# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Space: Files: List', type: :request do
  subject(:list) do
    api.rel(:collab_space).get(id: collab_space.id).value
      .rel(:files).get.value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:collab_space) { create(:collab_space) }

  context 'with existing files for the collabspace' do
    let!(:file_1) { create(:file, collab_space:, filename: 'first_file.pdf') }
    let!(:file_2) { create(:file, collab_space:, filename: 'second_file.pdf') }

    before { create(:file) }

    it { is_expected.to respond_with :ok }

    it 'properly decorates the files from S3' do
      expect(list).to contain_exactly(
        hash_including(
          'id' => file_1.id,
          'title' => 'My file',
          'original_filename' => 'first_file.pdf',
          'size' => 2048,
          'creator_id' => file_1.creator_id,
          'blob_url' => %r{^https://s3\.xikolo\.de/xikolo-collabspace/collabspaces/[\w-]+/uploads/[\w-]+/first_file\.pdf\?X-Amz-},
          'url' => "http://test.host/files/#{file_1.id}"
        ),
        hash_including(
          'id' => file_2.id,
          'title' => 'My file',
          'original_filename' => 'second_file.pdf',
          'size' => 2048,
          'creator_id' => file_2.creator_id,
          'blob_url' => %r{^https://s3\.xikolo\.de/xikolo-collabspace/collabspaces/[\w-]+/uploads/[\w-]+/second_file\.pdf\?X-Amz-},
          'url' => "http://test.host/files/#{file_2.id}"
        )
      )
    end
  end

  context 'when another collab space has files' do
    before { create(:file) }

    it { is_expected.to respond_with :ok }

    it 'returns an empty list' do
      expect(list).to eq []
    end
  end
end
