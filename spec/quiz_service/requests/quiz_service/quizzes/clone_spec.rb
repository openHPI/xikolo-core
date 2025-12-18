# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz: Clone', type: :request do
  subject(:clone) { quiz_api.rel(:clone).post.value! }

  let(:quiz) { create(:'quiz_service/quiz') }
  let(:api) { restify_with_headers(quiz_service_url).get.value }
  let(:quiz_api) { api.rel(:quiz).get({id: quiz.id}).value! }

  it { is_expected.to respond_with :created }

  it 'returns a matching quiz expect for the quiz id' do
    expect(clone.to_h).to include(quiz_api.except('id', 'submission_statistic_url'))
  end

  it 'copies quiz content' do
    q1 = create(:'quiz_service/multiple_choice_question', quiz:)
    create_list(:'quiz_service/text_answer', 3, question: q1)
    create(:'quiz_service/multiple_answer_question', quiz:)
    q3 = create(:'quiz_service/free_text_question', quiz:)
    create_list(:'quiz_service/free_text_answer', 3, question: q3)
    create(:'quiz_service/essay_question', quiz:)
    expect { clone }.to change(QuizService::Question, :count).from(4).to(8)
      .and change(QuizService::Answer, :count).from(6).to(12)
  end

  it 'copies embed files' do
    # Setup the quiz to clone with multiple file references:
    quiz.update instructions: "Inst\ns3://xikolo-quiz/quizzes/1/arch.jpg"
    q1 = create(:'quiz_service/multiple_answer_question', quiz:,
      text: "What?\ns3://xikolo-quiz/quizzes/1/arch.jpg\ns3://xikolo-quiz/quizzes/1/what.jpg",
      explanation: "Solution\ns3://xikolo-quiz/quizzes/1/arch.jpg")
    a = create(:'quiz_service/text_answer', question: q1, text: "A!\ns3://xikolo-quiz/quizzes/1/a.jpg", position: 1)
    b = create(:'quiz_service/text_answer', question: q1, text: "B!\ns3://xikolo-quiz/quizzes/1/b.jpg", position: 2)

    # Add requests stubs to call to copy all references S3 files:
    copy_arch_file = stub_request(:put, %r{https://s3.xikolo.de/xikolo-quiz
      /quizzes/[a-zA-Z0-9]+/arch.jpg}x).and_return(status: 200, body: '<xml></xml>')
    copy_what_file = stub_request(:put, %r{https://s3.xikolo.de/xikolo-quiz
      /quizzes/[a-zA-Z0-9]+/what.jpg}x).and_return(status: 200, body: '<xml></xml>')
    copy_a_file = stub_request(:put, %r{https://s3.xikolo.de/xikolo-quiz
      /quizzes/[a-zA-Z0-9]+/a.jpg}x).and_return(status: 200, body: '<xml></xml>')
    copy_b_file = stub_request(:put, %r{https://s3.xikolo.de/xikolo-quiz
      /quizzes/[a-zA-Z0-9]+/b.jpg}x).and_return(status: 200, body: '<xml></xml>')

    # executed the cloning and fetch to created quiz:
    new_quiz = QuizService::Quiz.find clone['id']

    # ensure file references of quiz itself have been updated:
    expect(new_quiz.instructions).not_to eq quiz.instructions
    expect(new_quiz.instructions).to start_with("Inst\ns3://xikolo-quiz/quizzes/")

    # ensure file references of question have been updated:
    new_question = new_quiz.questions.take
    expect(new_question.text).not_to eq q1.text
    expect(new_question.text).to start_with("What?\ns3://xikolo-quiz/quizzes/")
    expect(new_question.explanation).not_to eq q1.explanation
    expect(new_question.explanation).to start_with("Solution\ns3://xikolo-quiz/quizzes/")

    # ensure file references of answers have been updated:
    new_a, new_b = new_question.answers
    expect(new_a.text).not_to eq a.text
    expect(new_a.text).to start_with("A!\ns3://xikolo-quiz/quizzes/")
    expect(new_b.text).not_to eq b.text
    expect(new_b.text).to start_with("B!\ns3://xikolo-quiz/quizzes/")

    # ensure all files were copied exactly once (even for multiple references):
    expect(copy_arch_file).to have_been_requested
    expect(copy_what_file).to have_been_requested
    expect(copy_a_file).to have_been_requested
    expect(copy_b_file).to have_been_requested
  end
end
