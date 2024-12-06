# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::QuizAPI do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:json) { JSON.parse(response.body) }

  let(:user) { create(:user) }
  let(:course) { item.section.course }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code)
  end
  let(:item) { create(:item, content_id: quiz['id'], content_type: 'quiz') }
  let(:item_resource) do
    build(:'course:item',
      id: item.id, content_id: item.content_id,
      content_type: 'quiz', section_id: item.section_id)
  end
  let(:quiz) { build(:'quiz:quiz') }

  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_AUTHORIZATION' => "Legacy-Token #{stub_session_id}",
    }
  end

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.service(:course, build(:'course:root'))
    Stub.service(:quiz, build(:'quiz:root'))

    api_stub_user id: user.id # User with course enrollment

    Stub.request(:course, :get, '/courses', query: hash_including(user_id: user.id))
      .and_return Stub.json([course_resource])
    Stub.request(:course, :get, '/items', query: hash_including(content_id: item.content_id))
      .and_return Stub.json([item_resource])

    qq_1 =  build(:'quiz:question', :multi_select, quiz_id: quiz['id'])
    qq_2 =  build(:'quiz:question', :multi_select, quiz_id: quiz['id'])
    Stub.request(:quiz, :get, '/questions', query: {course_id: course.id, selftests: true})
      .to_return Stub.json([
        {
          id: qq_1['id'],
          quiz_id: qq_1['quiz_id'],
          text: qq_1['text'],
          points: qq_1['points'],
          type: qq_1['type'],
          answers: [
            build(:'quiz:answer', question_id: qq_1['id']),
            build(:'quiz:answer', question_id: qq_1['id']),
          ],
        },
        {
          id: qq_2['id'],
          quiz_id: qq_2['quiz_id'],
          text: qq_2['text'],
          points: qq_2['points'],
          type: qq_2['type'],
          answers: [
            build(:'quiz:answer', question_id: qq_2['id']),
            build(:'quiz:answer', question_id: qq_2['id']),
          ],
        },
      ])
  end

  describe 'GET /questions' do
    subject(:response) { get "/v2/questions?course_id=#{course.id}", nil, env_hash }

    it 'responds with 200 Ok' do
      expect(response).to have_http_status :ok
    end

    it "lists all questions and answers for the user's courses" do
      expect(json['questions'].size).to eq(2)
      expect(json['questions'].map(&:keys)).to all contain_exactly(
        'id',
        'points',
        'type',
        'text',
        'courseId',
        'quizId',
        'referenceLink',
        'answers'
      )
      expect(json['answers'].size).to eq(4)
      expect(json['answers'].map(&:keys)).to all contain_exactly(
        'id',
        'correct',
        'text'
      )
    end

    context 'when requesting a non-existing course' do
      subject(:response) { get "/v2/questions?course_id=#{SecureRandom.uuid}", nil, env_hash }

      it 'responds with an empty result' do
        expect(response).to have_http_status :ok
        expect(json).to eq({'questions' => [], 'answers' => []})
      end
    end
  end
end
