# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz Recap: Show', type: :request do
  subject(:request) { get '/app/quiz-recap', params:, headers: }

  let(:headers) { {} }
  let(:params) { {} }

  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }
  let(:section) { create(:section, course: course) }
  let(:items) do
    create_list(:item, 2, content_type: 'quiz', section:) {|quiz, i| quiz.content_id = quizzes[i]['id'] }
  end
  let(:item_resources) do
    build_list(:'course:item', 2, content_type: 'quiz') do |resource, i|
      resource['id'] = items[i].id
      resource['section_id'] = items[i].section_id
      resource['content_id'] = items[i].content_id
    end
  end
  let(:quizzes) { build_list(:'quiz:quiz', 2) }
  let(:questions) do
    build_list(:'quiz:question', 2, :multi_select) {|question, i| question['quiz_id'] = quizzes[i]['id'] }
  end
  let(:answers) do
    build_list(:'quiz:answer', 4) {|answer, i| answer['question_id'] = questions[i % 2]['id'] }
  end

  before do
    stub_user_request id: user.id

    Stub.service(:account, build(:'account:root'))
    Stub.service(:course, build(:'course:root'))
    Stub.service(:quiz, build(:'quiz:root'))

    Stub.request(:account, :get, '/sessions/')
      .and_return Stub.json(build(:'account:session', user_id: user.id))
  end

  context 'with an anonymous user' do
    it 'returns unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with a logged-in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    context 'without a course ID' do
      it 'returns a bad request status' do
        request
        expect(response).to have_http_status :bad_request
        expect(response.parsed_body).to include('error' => 'course_id is required')
      end
    end

    context 'without questions' do
      let(:params) { {course_id: 'empty-course'} }

      before do
        Stub.request(:quiz, :get, '/questions',
          query: {course_id: 'empty-course', selftests: true, exclude_from_recap: false, eligible_for_recap: true})
          .to_return Stub.json([])
      end

      it 'returns an empty question list' do
        request
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include('questions' => [])
      end
    end

    context 'with questions and answers' do
      let(:params) { {course_id: course.id} }

      before do
        Stub.request(:course, :get, '/courses', query: hash_including(user_id: user.id))
          .and_return Stub.json([course_resource])
        Stub.request(:course, :get, '/items',
          query: hash_including(content_id: items.first.content_id)).to_return Stub.json([item_resources.first])
        Stub.request(:course, :get, '/items',
          query: hash_including(content_id: items.second.content_id)).to_return Stub.json([item_resources.second])
        Stub.request(:quiz, :get, '/questions',
          query: {course_id: course.id, selftests: true, exclude_from_recap: false, eligible_for_recap: true})
          .to_return Stub.json([
            {
              id: questions.first['id'],
              quiz_id: questions.first['quiz_id'],
              text: questions.first['text'],
              points: questions.first['points'],
              type: questions.first['type'],
              answers: [
                answers[0],
                answers[2],
              ],
            },
            {
              id: questions.second['id'],
              quiz_id: questions.second['quiz_id'],
              text: questions.second['text'],
              points: questions.second['points'],
              type: questions.second['type'],
              answers: [
                answers[1],
                answers[3],
              ],
            },
          ])
      end

      it 'returns quiz data successfully' do
        request
        expect(response).to have_http_status :ok

        body = response.parsed_body

        expect(body['questions'].size).to eq(2)
        expect(body['questions'].map(&:keys)).to all contain_exactly(
          'id',
          'points',
          'type',
          'text',
          'referenceLink',
          'answers'
        )
        expect(body['questions'].first['answers'].size).to eq(2)
        expect(body['questions'].second['answers'].size).to eq(2)
        expect(body['questions'].first['answers']).not_to eq body['questions'].second['answers']
        expect(body['questions'].first['answers'].map(&:keys)).to all contain_exactly(
          'id',
          'correct',
          'text'
        )
      end
    end
  end
end
