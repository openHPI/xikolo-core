# frozen_string_literal: true

require 'spec_helper'

describe 'PeerAssessment Files: Create', type: :request do
  subject(:creation) do
    assessment_resource.rel(:files).post(params).value!
  end

  let!(:assessment) { create(:peer_assessment, id: '4290e188-6063-4721-95ea-c2b35bc95e86') }
  let(:user_id) { SecureRandom.uuid }
  let(:test_api) { Restify.new(:test).get.value! }
  let(:assessment_resource) { test_api.rel(:peer_assessment).get(id: assessment.id).value! }
  let(:upload_id) { 'b5f99337-224f-40f5-aa82-44ee8b272579' }
  let(:params) { {upload_uri: "upload://#{upload_id}/foo.jpg", user_id:} }

  it 'with valid upload creates a new file object' do
    stub_request(
      :head,
      'https://s3.xikolo.de/xikolo-uploads/' \
      'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
    ).and_return(
      status: 200,
      headers: {
        'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_assessment_attachment',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
        'Content-Length' => 1024,
        'Content-Type' => 'image/jpeg',
      }
    )
    store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                     /assessments/21BHFCPYoUuzziqRhNss7k
                     /attachments/[0-9a-zA-Z]+_foo.jpg}x
    stub_request(:head, store_regex).and_return(status: 404)
    stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')

    expect { creation }.to change(PeerAssessmentFile, :count).from(0).to(1)
    expect(assessment.reload.attachments).to eq []
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
        'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_assessment_attachment',
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
        'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_assessment_attachment',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
        'Content-Length' => 1024,
      }
    )
    store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                     /assessments/21BHFCPYoUuzziqRhNss7k
                     /attachments/[0-9a-zA-Z]+_foo.jpg}x
    stub_request(:head, store_regex).and_return(status: 404)
    stub_request(:put, store_regex).and_return(status: 503)

    expect { creation }.to raise_error(Restify::ClientError) do |error|
      expect(error.status).to eq :unprocessable_entity
    end
  end
end
