# frozen_string_literal: true

require 'spec_helper'

describe 'Submission: Show', type: :request do
  subject(:show) do
    test_api.rel(:submission).get(id: submission.id).value!
  end

  let(:assessment) { create(:peer_assessment) }
  let(:shared) { create(:shared_submission, peer_assessment: assessment) }
  let(:submission) { create(:submission, shared_submission: shared) }
  let(:test_api) { Restify.new(:test).get.value! }

  context 'with a valid assessment id' do
    it { is_expected.to respond_with :ok }

    it { is_expected.to include('id', 'text', 'submitted', 'attachments') }
  end

  context 'with non-existing peer assessment' do
    it 'returns with 404 not found' do
      expect { test_api.rel(:submission).get(id: SecureRandom.uuid).value! }.to \
        raise_error(Restify::NotFound)
    end
  end

  context 'with attachments' do
    let!(:file1) { create(:submission_file, shared_submission: shared) }
    let!(:file2) { create(:submission_file, shared_submission: shared, created_at: 10.minutes.ago) }
    let!(:file3) { create(:submission_file, shared_submission: shared, created_at: 10.minutes.from_now) }
    let!(:file4) { create(:submission_file, shared_submission: shared) }

    it 'returns the file resources decorated' do
      expect(show['attachments']).to all match hash_including(
        'id', 'user_id', 'name', 'download_url', 'mime_type', 'size', 'created_at'
      )
    end

    it 'responds with file of this submission in order of creation' do
      expect(show['attachments']).to match [
        hash_including('id' => file2.id),
        hash_including('id' => file1.id),
        hash_including('id' => file4.id),
        hash_including('id' => file3.id),
      ]
    end
  end
end
