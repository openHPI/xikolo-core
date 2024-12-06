# frozen_string_literal: true

require 'spec_helper'

describe 'Chatbot Bridge API: My Quizzes', type: :request do
  subject(:request) do
    get '/bridges/chatbot/my_quizzes', headers:, params:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:headers) { {'Authorization' => token} }
  let(:params) { {course_id: course['id']} }
  let(:json) { JSON.parse response.body }
  let(:course) { build(:'course:course') }
  let(:quizzes) { build_list(:'course:item', 2, :quiz, course_id: course['id']) }
  let(:questions1) { build_list(:'quiz:question', 1, :multi_select, quiz_id: quizzes.first['content_id']) }
  let(:questions2) { build_list(:'quiz:question', 1, :multi_select, quiz_id: quizzes.second['content_id']) }
  let(:answers1_1) { build_list(:'quiz:answer', 1, question_id: questions1.first['id']) }
  let(:answers2_1) { build_list(:'quiz:answer', 1, question_id: questions2.first['id']) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.service(:quiz, build(:'quiz:root'))
    Stub.request(:course, :get, '/items',
      query: {
        required_items: 'none',
        exercise_type: 'selftest',
        all_available: true,
        content_type: 'quiz',
        course_id: course['id'],
        user_id:,
      })
      .to_return Stub.json(quizzes)
    Stub.request(:quiz, :get, '/questions', query: {quiz_id: quizzes.first['content_id']})
      .to_return Stub.json(questions1)
    Stub.request(:quiz, :get, '/questions', query: {quiz_id: quizzes.second['content_id']})
      .to_return Stub.json(questions2)
    Stub.request(:quiz, :get, '/answers', query: {question_id: questions1.first['id']})
      .to_return Stub.json(answers1_1)
    Stub.request(:quiz, :get, '/answers', query: {question_id: questions2.first['id']})
      .to_return Stub.json(answers2_1)
  end

  it 'responds with quizzes' do
    request
    expect(response).to have_http_status :ok
    expect(json).to eq([
      {
        'quiz_id' => quizzes.first['id'],
        'course_id' => quizzes.first['course_id'],
        'questions' => [{
          'question_id' => questions1.first['id'],
          'question' => questions1.first['text'],
          'question_points' => questions1.first['points'],
          'question_explanation' => questions1.first['explanation'],
          'question_type' => questions1.first['type'],
          'answers' => [{
            'answer_id' => answers1_1.first['id'],
            'answer_text' => answers1_1.first['text'],
            'answer_explanation' => answers1_1.first['comment'],
            'answer_correct' => answers1_1.first['correct'],
          }],
        }],
      },
      {
        'quiz_id' => quizzes.second['id'],
        'course_id' => quizzes.second['course_id'],
        'questions' => [{
          'question_id' => questions2.first['id'],
          'question' => questions2.first['text'],
          'question_points' => questions2.first['points'],
          'question_explanation' => questions2.first['explanation'],
          'question_type' => questions2.first['type'],
          'answers' => [{
            'answer_id' => answers2_1.first['id'],
            'answer_text' => answers2_1.first['text'],
            'answer_explanation' => answers2_1.first['comment'],
            'answer_correct' => answers2_1.first['correct'],
          }],
        }],
      },
    ])
  end

  it 'has certain keys present' do
    request
    expect(json).to all include('quiz_id', 'course_id', 'questions')
  end

  context 'without Authorization header' do
    let(:headers) { {} }

    it 'complains about missing authorization' do
      request
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('You must provide an Authorization header to access this resource.')
    end
  end

  context 'with Invalid Signature' do
    let(:token) { 'Bearer 123123' }
    let(:headers) { {'Authorization' => token} }

    it 'complains about an invalid signature' do
      request
      expect(response).to have_http_status :unauthorized
      expect(json['title']).to eq('Invalid Signature')
    end
  end
end
