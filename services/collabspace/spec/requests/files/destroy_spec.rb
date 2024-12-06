# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collab Space: Files: Destroy', type: :request do
  subject(:destroy_file) do
    api.rel(:file).delete(id: file_id).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:file) { create(:file, filename: 'mystuff.pdf') }
  let(:file_id) { file.id }

  let!(:delete_stub) do
    stub_request(
      :delete,
      "https://s3.xikolo.de/xikolo-collabspace/collabspaces/#{file.collab_space_id}/uploads/#{file.id}/mystuff.pdf"
    ).to_return(status: 200, body: '', headers: {})
  end

  it 'deletes the file object' do
    expect { destroy_file }.to change(UploadedFile, :count).from(1).to(0)
  end

  it 'deletes the versions of the file object' do
    expect { destroy_file }.to change(FileVersion, :count).from(1).to(0)
  end

  it 'instruct s3 to remove the corresponding file object' do
    destroy_file
    expect(delete_stub).to have_been_requested
  end
end
