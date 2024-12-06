# frozen_string_literal: true

require 'spec_helper'

describe 'Submissions Files: Create', type: :request do
  subject(:creation) do
    submission_resource.rel(:files).post(params).value!
  end

  let(:shared_submission) do
    create(:shared_submission,
      peer_assessment: assessment)
  end
  let(:submission) do
    create(:submission,
      :with_pool_entries,
      user_id: SecureRandom.uuid,
      shared_submission:)
  end
  let!(:assessment) { create(:peer_assessment, :with_steps, id: '4290e188-6063-4721-95ea-c2b35bc95e86', allowed_attachments: 2) }
  let(:user_id) { SecureRandom.uuid }
  let(:test_api) { Restify.new(:test).get.value! }
  let(:submission_resource) { test_api.rel(:submission).get(id: submission.id).value! }
  let(:upload_id) { 'b5f99337-224f-40f5-aa82-44ee8b272579' }
  let(:params) { {upload_uri: "upload://#{upload_id}/foo.jpg", user_id:} }

  context 'unsubmitted' do
    let(:shared_submission) do
      create(:shared_submission,
        id: '17ddf3c3-6582-4e9f-8f6c-750829e0804b',
        peer_assessment: assessment)
    end

    before { create(:submission_file, shared_submission:) }

    it 'rejects upload if allow attachments is exceed' do
      create(:submission_file, shared_submission:)

      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 1024,
          'Content-Type' => 'image/jpeg',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end

    it 'with valiad upload creates a new file object' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 1024,
          'Content-Type' => 'image/jpeg',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/21BHFCPYoUuzziqRhNss7k
                       /submissions/J2fRUmHJl562HNvq1Jdij
                       /attachments/[0-9a-zA-Z]+.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')

      expect { creation }.to change(SubmissionFile, :count).from(1).to(2)
      expect(creation).to respond_with :created
    end

    it 'rejects invalid upload and does not create a file object' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 1024,
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/21BHFCPYoUuzziqRhNss7k
                       /submissions/J2fRUmHJl562HNvq1Jdij
                       /attachments/[0-9a-zA-Z]+.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end
  end

  context 'submitted but attempts left' do
    let(:shared_submission) do
      create(:shared_submission,
        :as_submitted,
        id: '17ddf3c3-6582-4e9f-8f6c-750829e0804b',
        additional_attempts: 1,
        peer_assessment: assessment)
    end

    it 'with valiad upload creates a new file object' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 1024,
          'Content-Type' => 'image/jpeg',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/21BHFCPYoUuzziqRhNss7k
                       /submissions/J2fRUmHJl562HNvq1Jdij
                       /attachments/[0-9a-zA-Z]+.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')

      expect { creation }.to change(SubmissionFile, :count).from(0).to(1)
      expect(creation).to respond_with :created
    end

    it 'rejects invalid upload and does not create a file object' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_submission_attachment',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
          'Content-Length' => 1024,
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/21BHFCPYoUuzziqRhNss7k
                       /submissions/J2fRUmHJl562HNvq1Jdij
                       /attachments/[0-9a-zA-Z]+.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end
  end

  context 'submitted without attempts left' do
    let(:shared_submission) do
      create(:shared_submission,
        :as_submitted,
        id: '17ddf3c3-6582-4e9f-8f6c-750829e0804b',
        additional_attempts: 0,
        peer_assessment: assessment)
    end

    it 'rejects to upload' do
      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :forbidden
      end
    end
  end
end
