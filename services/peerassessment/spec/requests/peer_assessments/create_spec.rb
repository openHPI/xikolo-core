# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PeerAssessment: Create', type: :request do
  subject(:creation) { api.rel(:peer_assessments).post(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { attributes_for(:peer_assessment) }

  it { is_expected.to respond_with :created }

  it 'creates a new peerassessment' do
    expect { creation }.to change(PeerAssessment, :count).from(0).to(1)
  end

  context 'instructions with file upload references' do
    let(:instructions) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:params) { super().merge instructions: }

    it 'stores valid upload and creates a new peerassessment' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { creation }.to change(PeerAssessment, :count).from(0).to(1)
      expect(PeerAssessment.find(creation['id']).instructions).to include 's3://xikolo-peerassessment/assessments'
    end

    it 'rejects invalid upload and does not creates a new peerassessment' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_instructions',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'instructions' => ['rtfile_rejected']
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
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/[0-9a-zA-Z]+/rtfiles/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'instructions' => ['rtfile_error']
      end
    end
  end
end
