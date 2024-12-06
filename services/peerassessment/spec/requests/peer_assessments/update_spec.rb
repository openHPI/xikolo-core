# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PeerAssessment: Update', type: :request do
  subject(:modification) { api.rel(:peer_assessment).patch(params, id: assessment.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:assessment) { create(:peer_assessment) }
  let(:params) { {allowed_attachments: 3} }

  it { is_expected.to respond_with :no_content }

  it 'update the peerassessment' do
    expect { modification; assessment.reload }.to change(assessment, :allowed_attachments).to(3)
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
      expect { modification; assessment.reload }.to change(assessment, :instructions)
      expect(assessment.instructions).to include 's3://xikolo-peerassessment/assessments'
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq 'instructions' => ['rtfile_error']
      end
    end
  end

  context 'with old file references' do
    let(:assessment) { create(:peer_assessment, instructions: "Headline\ns3://xikolo-peerassessment/assessments/1/rtfiles/2/test.pdf") }
    let(:params) { super().merge instructions: "Headline\nNo content" }

    it 'deletes no-longer referenced files' do
      cleanup_stub = stub_request(
        :delete,
        'https://s3.xikolo.de/xikolo-peerassessment/assessments/1/rtfiles/2/test.pdf'
      ).and_return(status: 200)

      expect { modification; assessment.reload }.to change(assessment, :instructions)
      expect(assessment.instructions).not_to include 's3://xikolo-peerassessment/assessments'
      expect(cleanup_stub).to have_been_requested
    end
  end
end
