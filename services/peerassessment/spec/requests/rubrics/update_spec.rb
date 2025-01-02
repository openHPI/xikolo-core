# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rubric: Update', type: :request do
  subject(:modification) { api.rel(:rubric).patch(params, id: rubric.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:rubric) { create(:rubric) }
  let(:params) { {title: 'Important Rubric'} }

  it { is_expected.to respond_with :no_content }

  it 'update the peerassessment' do
    expect { modification; rubric.reload }.to change(rubric, :title).to('Important Rubric')
  end

  context 'hints with file upload references' do
    let(:hints) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:params) { super().merge hints: }

    it 'stores valid upload and creates a new peerassessment' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_rubric_hints',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/[0-9a-zA-Z]+
                       /rubrics/[0-9a-zA-Z]+
                       /rtfiles/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { modification; rubric.reload }.to change(rubric, :hints)
      expect(rubric.hints).to include 's3://xikolo-peerassessment/assessments'
    end

    it 'rejects invalid upload and does not creates a new peerassessment' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_rubric_hints',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'hints' => ['rtfile_rejected']
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
          'X-Amz-Meta-Xikolo-Purpose' => 'peerassessment_rubric_hints',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-peerassessment
                       /assessments/[0-9a-zA-Z]+
                       /rubrics/[0-9a-zA-Z]+
                       /rtfiles/[0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'hints' => ['rtfile_error']
      end
    end
  end

  context 'with old file references' do
    let(:rubric) { create(:rubric, hints: "Headline\ns3://xikolo-peerassessment/assessments/1/rubrics/2/rtfiles/3/test.pdf") }
    let(:params) { super().merge hints: "Headline\nNo content" }

    it 'deletes no-longer referenced files' do
      cleanup_stub = stub_request(
        :delete,
        'https://s3.xikolo.de/xikolo-peerassessment/assessments/1/rubrics/2/rtfiles/3/test.pdf'
      ).and_return(status: 200)

      expect { modification; rubric.reload }.to change(rubric, :hints)
      expect(rubric.hints).not_to include 's3://xikolo-peerassessment/assessments'
      expect(cleanup_stub).to have_been_requested
    end
  end
end
