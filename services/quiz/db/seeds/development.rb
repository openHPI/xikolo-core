# frozen_string_literal: true

# Quiz 1
welcome_quiz = Quiz.create! id: '00000001-3800-4444-9999-000000000001',
  instructions: 'This is the first Quiz\n\nplease do ***not*** cheat!',
  time_limit_seconds: 3600,
  unlimited_time: false,
  allowed_attempts: 1,
  unlimited_attempts: true

internet_question = Question.create! quiz: welcome_quiz,
  text: 'What is the Internet?',
  points: 3,
  explanation: 'It is a network of networks that consists of millions of private, public, academic, business, and government networks, of local to global scope, that are linked by a broad array of electronic, wireless, and optical networking technologies.',
  shuffle_answers: false,
  type: MultipleAnswerQuestion.name,
  position: 1

Answer.create! question: internet_question,
  comment: 'Correct Answer!',
  correct: true,
  text: 'The Internet is a global system of interconnected computer networks that use the standard Internet protocol suite (TCP/IP) to serve several billion users worldwide.',
  type: TextAnswer.name,
  position: 1

Answer.create! question: internet_question,
  comment: 'Wrong Answer!',
  correct: false,
  text: 'The Internet consists of cookies.',
  type: TextAnswer.name,
  position: 2

www_question = Question.create! quiz: welcome_quiz,
  text: 'What does WWW stand for?',
  points: 3,
  explanation: 'The World Wide Web (abbreviated as WWW or W3, commonly known as the web) is a system of interlinked hypertext documents accessed via the Internet.',
  shuffle_answers: false,
  type: MultipleChoiceQuestion.name,
  position: 2

Answer.create! question: www_question,
  comment: 'Wrong Answer!!',
  correct: false,
  text: 'We Want Web',
  type: TextAnswer.name,
  position: 1

Answer.create! question: www_question,
  comment: 'Correct Answer!',
  correct: true,
  text: 'World Wide Web',
  type: TextAnswer.name,
  position: 2

# Quiz 2
http_quiz = Quiz.create! id: '00000001-3800-4444-9999-000000000002',
  instructions: 'This quiz should help you to check your new knowledge',
  time_limit_seconds: 3600,
  unlimited_time: true,
  allowed_attempts: 2,
  unlimited_attempts: true

http_question = Question.create! quiz: http_quiz,
  text: 'What is HTTP?',
  points: 3,
  explanation: 'The Hypertext Transfer Protocol (HTTP) is an application protocol for distributed, collaborative, hypermedia information systems.',
  shuffle_answers: false,
  type: MultipleChoiceQuestion.name,
  position: 1

Answer.create! question: http_question,
  comment: 'Wrong Answer!!',
  correct: false,
  text: 'Hyper Turbo Transformation Protocol',
  type: TextAnswer.name,
  position: 1

Answer.create! question: http_question,
  comment: 'Correct Answer!',
  correct: true,
  text: 'Hypertext Transfer Protocol',
  type: TextAnswer.name,
  position: 2

http_req_question = Question.create! quiz: http_quiz,
  text: "Enter the HTTP status code for the client error 'File not found'",
  points: 3,
  explanation: 'Visit http://en.wikipedia.org/wiki/List_of_HTTP_status_codes for some hints!',
  shuffle_answers: false,
  type: FreeTextQuestion.name,
  position: 2

Answer.create! question: http_req_question,
  correct: true,
  text: '404',
  type: FreeTextAnswer.name,
  position: 1

# Quiz 3 - Survey

survey_quiz = Quiz.create! id: '00000001-3800-4444-9999-000000000003',
  instructions: 'This is a survey about your motivation for this course. We would appreciate if you take 5-10min to answer some questions to improve your learning experience!',
  time_limit_seconds: 3600,
  unlimited_time: true,
  allowed_attempts: 1,
  unlimited_attempts: false

survey_question_1 = Question.create! quiz: survey_quiz,
  text: 'Why did you sign up for this course?',
  points: 1,
  shuffle_answers: false,
  type: MultipleAnswerQuestion.name,
  position: 1

Answer.create! question: survey_question_1,
  text: 'I am interested in the topic Internet and WWW',
  type: TextAnswer.name,
  position: 1

Answer.create! question: survey_question_1,
  text: 'I want to improve my skills in IPv6',
  type: TextAnswer.name,
  position: 2

# This will render as a dropdown because it has so many options
survey_question_2 = MultipleChoiceQuestion.create!(
  quiz: survey_quiz,
  text: 'Not knowing the course yet - how would you rate it?',
  points: 1,
  shuffle_answers: false,
  position: 2
)

(1..10).each do |rating|
  TextAnswer.create!(
    question: survey_question_2,
    text: rating.to_s,
    position: rating
  )
end

# Quiz 4 - Homework
homework_quiz = Quiz.create! id: '00000001-3800-4444-9999-000000000004',
  instructions: 'This is this weeks homework assignments. Better be good, it counts!',
  time_limit_seconds: 3600,
  unlimited_time: false,
  allowed_attempts: 1,
  unlimited_attempts: false

pimpmaster_question = Question.create! quiz: homework_quiz,
  text: 'Wer ist der Beste?',
  points: 3,
  shuffle_answers: true,
  type: MultipleChoiceQuestion.name,
  position: 1

Answer.create! question: pimpmaster_question,
  comment: 'Correct Answer!',
  correct: true,
  text: 'Pimpmaster 3000',
  type: TextAnswer.name,
  position: 1

Answer.create! question: pimpmaster_question,
  comment: 'Wrong Answer!',
  correct: false,
  text: 'Justin Bieber',
  type: TextAnswer.name,
  position: 2

# Quiz 5 - Final Exam
exam_quiz = Quiz.create! id: '00000001-3800-4444-9999-000000000005',
  instructions: 'This is this weeks homework assignments. Better be good, it counts!',
  time_limit_seconds: 3600,
  unlimited_time: false,
  allowed_attempts: 1,
  unlimited_attempts: false

exam_question = Question.create! quiz: exam_quiz,
  text: 'Who let the dogs out?',
  points: 30,
  shuffle_answers: true,
  type: MultipleAnswerQuestion.name,
  position: 1

(1..3).each do |i|
  Answer.create! question: exam_question,
    comment: 'Correct Answer!',
    correct: true,
    text: 'Who?',
    type: TextAnswer.name,
    position: i
end

# Quiz 6 - All question types
Quiz.create!(
  id: '00000001-3800-4444-9999-000000000006',
  instructions: 'Try out all available question types in this quiz!',
  time_limit_seconds: 3600,
  unlimited_time: true,
  allowed_attempts: 1,
  unlimited_attempts: true
).tap do |quiz|
  quiz.questions.create!(
    text: 'Which answer is right?',
    points: 3,
    shuffle_answers: true,
    type: MultipleChoiceQuestion.name,
    position: 1
  ).tap do |question|
    question.answers.create!(
      comment: 'Correct Answer!',
      correct: true,
      text: 'Correct',
      type: TextAnswer.name,
      position: 1
    )

    question.answers.create!(
      comment: 'Wrong Answer!',
      correct: false,
      text: 'Wrong',
      type: TextAnswer.name,
      position: 2
    )
  end

  quiz.questions.create!(
    text: 'Which answers are right?',
    points: 3,
    shuffle_answers: true,
    type: MultipleAnswerQuestion.name,
    position: 2
  ).tap do |question|
    question.answers.create!(
      comment: 'Correct Answer!',
      correct: true,
      text: 'Correct',
      type: TextAnswer.name,
      position: 1
    )

    question.answers.create!(
      comment: 'Another correct answer!',
      correct: true,
      text: 'Also correct',
      type: TextAnswer.name,
      position: 2
    )

    question.answers.create!(
      comment: 'Wrong Answer!',
      correct: false,
      text: 'Wrong',
      type: TextAnswer.name,
      position: 3
    )
  end

  quiz.questions.create!(
    text: 'Name the best MOOC platform:',
    points: 3,
    type: FreeTextQuestion.name,
    position: 3
  ).tap do |question|
    question.answers.create!(
      correct: true,
      text: 'Company',
      type: FreeTextAnswer.name,
      position: 1
    )
  end

  quiz.questions.create!(
    text: 'Please let us know your feedback:',
    points: 3,
    type: EssayQuestion.name,
    position: 4
  )
end

# A quiz submission with proctoring data (passed with violations) in the proctoring course
submission = welcome_quiz.attempt! '00000001-3100-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000008',
  vendor_data: {
    'proctoring' => 'smowl_v2',
    'proctoring_smowl_v2' => {
      'nobodyinthepicture' => 0, 'wronguser' => 0, 'severalpeople' => 0,
      'webcamcovered' => 0, 'invalidconditions' => 0,
      'webcamdiscarted' => 0, 'notallowedelement' => 0, 'nocam' => 1,
      'otherappblockingthecam' => 0, 'notsupportedbrowser' => 0,
      'othertab' => 2, 'emptyimage' => 0, 'suspicious' => 0
    },
  }

q1 = QuizSubmissionQuestion.create!(
  quiz_submission_id: submission.id,
  quiz_question_id: internet_question.id
)
internet_question.create_answer! q1, internet_question.answers.where(correct: true).ids
internet_question.update_points_from_submission q1, internet_question.answers.where(correct: true).ids

q2 = QuizSubmissionQuestion.create!(
  quiz_submission_id: submission.id,
  quiz_question_id: www_question.id
)
www_question.create_answer! q2, www_question.answers.find_by(correct: true).id
www_question.update_points_from_submission q2, www_question.answers.find_by(correct: true).id

submission.update!(
  quiz_submission_time: 1.minute.from_now,
  quiz_version_at: submission.quiz_access_time
)
submission.schedule_report!
submission.preaggregate_statistics!
