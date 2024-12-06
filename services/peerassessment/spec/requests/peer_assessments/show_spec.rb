# frozen_string_literal: true

require 'spec_helper'

describe 'PeerAssessment: Show', type: :request do
  subject(:show) do
    test_api.rel(:peer_assessment).get(params).value!
  end

  let(:params) { {id: assessment.id} }
  let!(:assessment) { create(:peer_assessment, instructions:) }
  let(:instructions) { 'ToDo!' }
  let(:user_id) { SecureRandom.uuid }
  let(:test_api) { Restify.new(:test).get.value! }

  context 'with a valid assessment id' do
    it { is_expected.to respond_with :ok }

    it { is_expected.to include('id', 'title', 'instructions', 'attachments') }
  end

  context 'with non-existing peer assessment' do
    it 'returns with 404 not found' do
      expect { test_api.rel(:peer_assessment).get(id: SecureRandom.uuid).value! }.to \
        raise_error(Restify::NotFound)
    end
  end

  describe '#attachments' do
    before { create(:peer_assessment_file, peer_assessment: assessment) }

    it 'returns the file resources decorated' do
      expect(show['attachments'].size).to eq 1
      expect(show['attachments'][0].keys).to match_array %w[id user_id name download_url mime_type size created_at]
    end
  end

  describe '#instructions' do
    let(:instructions) { 'some text\ns3://xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg' }

    it 'returns text with public URLs' do
      expect(show['instructions']).to eq 'some text\nhttps://s3.xikolo.de/xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg'
    end

    context 'in raw mode' do
      let(:params) { super().merge raw: true }

      it 'returns the markup enhanced with url mappings and other files references' do
        expect(show['instructions']).to eq(
          'markup' =>
            'some text\ns3://xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg',
          'url_mapping' => {
            's3://xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg' =>
               'https://s3.xikolo.de/xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg',
          },
          'other_files' => {
            's3://xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg' => 'hans.jpg',
          }
        )
      end
    end
  end
end
