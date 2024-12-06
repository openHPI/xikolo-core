# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Answer: Show', type: :request do
  subject(:show) { api.rel(:answer).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:answer) { create(:answer) }
  let(:params) { {id: answer.id} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it { is_expected.to include('id', 'question_id', 'text', 'comment', 'position', 'correct', 'type') }
  end

  context 'text' do
    let(:answer) { create(:answer, text: 'headline\n==\ns3://xikolo-quiz/quizzes/324/foo.jpg') }

    it 'returns markup with external URLs' do
      expect(show['text']).to eq 'headline\n==\nhttps://s3.xikolo.de/xikolo-quiz/quizzes/324/foo.jpg'
    end

    context 'in raw access' do
      let(:params) { super().merge raw: true }

      it 'returns the markup structured' do
        expect(show['text']).to eq(
          'markup' => 'headline\n==\ns3://xikolo-quiz/quizzes/324/foo.jpg',
          'url_mapping' => {
            's3://xikolo-quiz/quizzes/324/foo.jpg' =>
              'https://s3.xikolo.de/xikolo-quiz/quizzes/324/foo.jpg',
          },
          'other_files' => {
            's3://xikolo-quiz/quizzes/324/foo.jpg' => 'foo.jpg',
          }
        )
      end
    end
  end
end
