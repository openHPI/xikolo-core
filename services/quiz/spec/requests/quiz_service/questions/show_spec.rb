# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: Show', type: :request do
  subject(:show) { api.rel(:question).get(params).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let(:question) { create(:'quiz_service/multiple_choice_question') }
  let(:params) { {id: question.id} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it { is_expected.to include('id', 'quiz_id', 'text', 'text', 'explanation', 'points', 'shuffle_answers', 'type', 'position') }
  end

  context 'text' do
    let(:question) { create(:'quiz_service/multiple_choice_question', text: 'headline\n==\ns3://xikolo-quiz/quizzes/324/235_foo.jpg') }

    it 'returns markup with external URLs' do
      expect(show['text']).to eq 'headline\n==\nhttps://s3.xikolo.de/xikolo-quiz/quizzes/324/235_foo.jpg'
    end

    context 'in raw access' do
      let(:params) { super().merge raw: true }

      it 'returns the markup structured' do
        expect(show['text']).to eq(
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

  context 'explanation' do
    let(:question) { create(:'quiz_service/multiple_choice_question', explanation: 'headline\n==\ns3://xikolo-quiz/quizzes/324/235_foo.jpg') }

    it 'returns markup with external URLs' do
      expect(show['explanation']).to eq 'headline\n==\nhttps://s3.xikolo.de/xikolo-quiz/quizzes/324/235_foo.jpg'
    end

    context 'in raw access' do
      let(:params) { super().merge raw: true }

      it 'returns the markup structured' do
        expect(show['explanation']).to eq(
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
