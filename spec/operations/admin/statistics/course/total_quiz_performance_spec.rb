# frozen_string_literal: true

require 'spec_helper'

describe Admin::Statistics::Course::TotalQuizPerformance do
  before do
    quiz1 = build(:'course:item', :quiz, content_id: 'quiz-1', exercise_type: 'main')
    quiz2 = build(:'course:item', :quiz, content_id: 'quiz-2', exercise_type: 'bonus')

    Stub.request(:course, :get, '/items', query: hash_including(
      course_id: 'test-course',
      content_type: 'quiz',
      exercise_type: 'main,bonus',
      was_available: 'true'
    )).to_return Stub.json([quiz1, quiz2])

    Stub.request(:quiz, :get, '/submission_statistics/quiz-1')
      .to_return Stub.json({'avg_points' => 80, 'max_points' => 100})
    Stub.request(:quiz, :get, '/submission_statistics/quiz-2')
      .to_return Stub.json({}) # Missing stats
  end

  it 'aggregates stats across quizzes and skips missing ones' do
    result = described_class.call(course_id: 'test-course', type: :graded)

    expect(result).to be(0.8) # Only quiz1: 80/100
  end
end
