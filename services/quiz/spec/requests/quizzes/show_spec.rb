# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz: Show', type: :request do
  subject(:show) { api.rel(:quiz).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:quiz) { create(:quiz) }
  let(:params) { {id: quiz.id} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it { is_expected.to include('id', 'instructions', 'time_limit_seconds', 'unlimited_time', 'allowed_attempts', 'unlimited_attempts', 'max_points', 'external_ref_id') }
  end

  context 'instructions' do
    let(:quiz) { create(:quiz, instructions: 'headline\n==\ns3://xikolo-quiz/quizzes/324/235_foo.jpg') }

    it 'returns markup with external URLs' do
      expect(show['instructions']).to eq 'headline\n==\nhttps://s3.xikolo.de/xikolo-quiz/quizzes/324/235_foo.jpg'
    end

    context 'in raw access' do
      let(:params) { super().merge raw: true }

      it 'returns the markup structured' do
        expect(show['instructions']).to eq(
          'markup' => 'headline\n==\ns3://xikolo-quiz/quizzes/324/235_foo.jpg',
          'url_mapping' => {
            's3://xikolo-quiz/quizzes/324/235_foo.jpg' =>
              'https://s3.xikolo.de/xikolo-quiz/quizzes/324/235_foo.jpg',
          },
          'other_files' => {
            's3://xikolo-quiz/quizzes/324/235_foo.jpg' => '235_foo.jpg',
          }
        )
      end
    end
  end
end
