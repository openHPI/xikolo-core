# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz Recap: Show', type: :request do
  subject(:request) { get '/app/quiz-recap', params:, as: :json }

  let(:params) { {} }

  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course) }
  let(:section) { create(:'course_service/section', course:) }
  let(:items) do
    quizzes.map do |quiz|
      create(:'course_service/item', :quiz, section:, content: quiz)
    end
  end
  let(:quizzes) { create_list(:'quiz_service/quiz', 2) }
  let(:questions) do
    quizzes.map do |quiz|
      create(:'quiz_service/multiple_answer_question', quiz:, text: 'Question')
    end
  end
  let(:answers) do
    questions.map do |question|
      [
        create(:'quiz_service/answer', question:, text: 'Answer A', correct: true),
        create(:'quiz_service/answer', question:, text: 'Answer B', correct: false),
      ]
    end.flatten
  end

  context 'with an anonymous user' do
    it 'redirects to sessions new path' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with a logged-in user' do
    before { sign_in(user:) }

    context 'without a course ID' do
      it 'returns a bad request status' do
        request
        expect(response).to have_http_status :bad_request
        expect(response.parsed_body).to include('error' => 'course_id is required')
      end
    end

    context 'without questions' do
      let(:params) { {course_id: 'empty-course'} }

      it 'returns an empty question list' do
        request
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include('questions' => [])
      end
    end

    context 'with questions and answers' do
      let(:params) { {course_id: course.id} }

      before do
        items
        answers
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
