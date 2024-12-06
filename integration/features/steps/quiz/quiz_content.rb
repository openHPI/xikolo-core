# frozen_string_literal: true

module Steps
  module QuizContent
    def create_quiz(attrs = {})
      data = {
        instructions: "This is the first Quiz\n\nplease do ***not*** cheat!",
        time_limit_seconds: 3600,
        unlimited_time: false,
        allowed_attempts: 2,
        unlimited_attempts: false,
      }
      data.merge! attrs
      data.compact!

      Server[:quiz].api.rel(:quizzes).post(data).value!
    end

    def create_question(attrs = {})
      quiz = context.fetch :quiz
      quiz['max_points'] ||= 0
      quiz['max_points'] += 3

      explanation = <<~TEXT.strip
        It is a network of networks that consists of millions of \
        private, public, academic, business, and government \
        networks, of local to global scope, that are linked \
        by a broad array of electronic, wireless, and optical \
        networking technologies.
      TEXT

      data = {
        quiz_id: quiz['id'],
        text: 'What is the Internet?',
        points: 3,
        explanation:,
        shuffle_answers: false,
        type: 'MultipleAnswerQuestion',
        position: 1,
      }
      data.merge! attrs
      data.compact!

      Server[:quiz].api.rel(:questions).post(data).value!
    end

    def create_answers(attrs = {})
      question = context.fetch :quiz_question

      text = <<~TEXT.strip
        The Internet is a global system of interconnected computer \
        networks that use the standard Internet protocol suite \
        (TCP/IP) to serve several billion users worldwide.
      TEXT

      ## first answer
      data = {
        question_id: question['id'],
        comment: 'Correct Answer!',
        correct: true,
        text:,
        type: 'TextAnswer',
        position: 1,
      }
      data.merge! attrs
      data.compact!

      answer1 = Server[:quiz].api.rel(:text_answers).post(data).value!

      ## second answer
      data = {
        question_id: question['id'],
        comment: 'Wrong Answer!',
        correct: false,
        text: 'The Internet consists of cookies.',
        type: 'TextAnswer',
        position: 2,
      }
      data.merge! attrs
      data.compact!

      answer2 = Server[:quiz].api.rel(:text_answers).post(data).value!

      context.assign :answer_1, answer1
      context.assign :answer_2, answer2
      [answer1, answer2]
    end

    Given 'a quiz was created' do
      context.assign :quiz, create_quiz
    end

    Given 'a quiz question was created' do
      context.assign :quiz_question, create_question
    end
    Given 'a quiz single select question was created' do
      context.assign :quiz_mc_question, create_question(type: 'MultipleChoiceQuestion')
    end
    Given 'answers were created' do
      context.assign :quiz_answers, create_answers
    end

    Given 'a quiz with one question and answers was created' do
      send :'Given a quiz was created'
      send :'Given a quiz question was created'
      send :'Given answers were created'
    end

    Given 'a quiz with questions and answers was created' do
      send :'Given a quiz was created'
      send :'Given a quiz question was created'
      send :'Given a quiz single select question was created'
      send :'Given answers were created'
    end

    def allow_unlimited_attempts(quiz)
      Server[:quiz].api.rel(:quiz).put({unlimited_attempts: true},
        {id: quiz.id}).value
    end

    Given 'the quiz has unlimited attempts' do
      context.with :quiz do |quiz|
        allow_unlimited_attempts quiz
      end
    end

    Given 'a survey was created' do
      context.assign :quiz, create_quiz
      context.with :quiz do |quiz|
        create_survey quiz
      end
    end

    Given 'a survey with questions and answers was created' do
      send :'Given a survey was created'
      send :'Given a quiz question was created'
      send :'Given answers were created'
    end

    def create_survey(quiz)
      Server[:quiz].api.rel(:quiz).patch(
        {allowed_attempts: 1, unlimited_attempts: false},
        {id: quiz.id}
      ).value!
    end
  end
end

Gurke.configure {|c| c.include Steps::QuizContent }
