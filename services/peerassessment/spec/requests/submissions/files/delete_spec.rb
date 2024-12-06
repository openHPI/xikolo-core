# frozen_string_literal: true

require 'spec_helper'

describe 'Submissions Files: Delete', type: :request do
  subject(:deletion) do
    submission_resource.rel(:file).delete(id: file.id).value!
  end

  let(:shared_submission) do
    create(:shared_submission,
      attachments: [file_id],
      peer_assessment: assessment)
  end
  let(:submission) do
    create(:submission,
      :with_pool_entries,
      user_id: SecureRandom.uuid,
      shared_submission:)
  end
  let!(:assessment) { create(:peer_assessment, :with_steps) }
  let!(:file) { create(:submission_file, storage_uri: 's3://xikolo-pa/pas/34/submissions/34/23.jpg', shared_submission:) }
  let(:user_id) { SecureRandom.uuid }
  let(:test_api) { Restify.new(:test).get.value! }
  let(:submission_resource) { test_api.rel(:submission).get(id: submission.id).value! }
  let!(:s3_deletion) do
    stub_request(:delete,
      'https://s3.xikolo.de/xikolo-pa/pas/34/submissions/34/23.jpg')
  end

  context 'unsubmitted' do
    let(:shared_submission) do
      create(:shared_submission,
        peer_assessment: assessment)
    end

    it 'removes the file from database and s3' do
      expect { deletion }.to change(SubmissionFile, :count).from(1).to(0)
      expect(s3_deletion).to have_been_requested
    end
  end

  context 'submitted but attempts left' do
    let(:shared_submission) do
      create(:shared_submission,
        :as_submitted,
        additional_attempts: 1,
        peer_assessment: assessment)
    end

    it 'removes the file from database and s3' do
      expect { deletion }.to change(SubmissionFile, :count).from(1).to(0)
      expect(s3_deletion).to have_been_requested
    end
  end

  context 'submitted without attempts left' do
    let(:shared_submission) do
      create(:shared_submission,
        :as_submitted,
        additional_attempts: 0,
        peer_assessment: assessment)
    end

    it 'does not removes the file from database or s3' do
      expect { deletion }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :forbidden
      end
      expect(SubmissionFile.count).to eq 1
      expect(s3_deletion).not_to have_been_requested
    end
  end
end
