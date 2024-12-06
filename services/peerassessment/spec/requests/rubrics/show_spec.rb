# frozen_string_literal: true

require 'spec_helper'

describe 'Rubrics: Show', type: :request do
  subject(:show) do
    test_api.rel(:rubric).get(params).value!
  end

  let(:params) { {id: rubric.id} }
  let!(:rubric) { create(:rubric, hints:) }
  let(:hints) { 'ToDo!' }
  let(:test_api) { Restify.new(:test).get.value! }

  context 'with a valid review id' do
    it { is_expected.to respond_with :ok }

    it { is_expected.to include('id', 'title', 'hints', 'peer_assessment_id', 'position') }
  end

  describe '#hints' do
    let(:hints) { 'some text\ns3://xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg' }

    it 'returns text with public URLs' do
      expect(show['hints']).to eq 'some text\nhttps://s3.xikolo.de/xikolo-peerassessment/peerassessments/34/rtfiles/34/hans.jpg'
    end

    context 'in raw mode' do
      let(:params) { super().merge raw: true }

      it 'returns the markup enhanced with url mappings and other files references' do
        expect(show['hints']).to eq(
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
