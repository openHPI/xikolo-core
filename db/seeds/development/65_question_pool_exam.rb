# frozen_string_literal: true

# A valid exam pool for trying the learner and editor flows locally.
# Each attempt displays 3 easy, 3 mid, and 4 hard questions in a persisted random order.
quiz = QuizService::Quiz.find_or_initialize_by(id: '00000001-3800-4444-9999-000000000007')
quiz.assign_attributes(
  instructions: <<~MARKDOWN,
    ## Question Pool Exam

    This development exam displays 10 randomly selected questions from a pool
    of 30. Each learner receives 3 easy, 3 mid, and 4 hard questions. Refresh
    the attempt or take the second attempt to verify that the selected
    questions and their order remain stable.
  MARKDOWN
  time_limit_seconds: 3600,
  unlimited_time: false,
  allowed_attempts: 2,
  unlimited_attempts: false,
  question_pool: true,
  displayed_question_count: 10,
  pass_percentage: 70,
  external_ref_id: 'development-question-pool-exam'
)
quiz.save!

if quiz.questions.empty?
  30.times do |index|
    question_number = index + 1
    question_class = index.even? ? QuizService::MultipleChoiceQuestion : QuizService::MultipleAnswerQuestion
    question = question_class.create!(
      quiz:,
      text: "Question #{question_number}: select the correct development answer.",
      explanation: 'This question belongs to the development question pool.',
      points: if index < 10
                1
              else
                index < 20 ? 2 : 3
              end,
      shuffle_answers: true,
      position: question_number
    )

    question.answers.create!(
      text: "Correct answer for question #{question_number}",
      correct: true,
      type: QuizService::TextAnswer.name,
      position: 1
    )
    question.answers.create!(
      text: "Incorrect answer for question #{question_number}",
      correct: false,
      type: QuizService::TextAnswer.name,
      position: 2
    )
  end
elsif quiz.questions.count != 30
  raise "Expected the development question pool to contain 30 questions, found #{quiz.questions.count}."
end

section = CourseService::Section.find('00000002-3100-4444-9999-000000000007')
item = CourseService::Item.find_or_initialize_by(id: '00000003-3100-4444-9999-000000000043')
item.assign_attributes(
  title: 'Question Pool Exam',
  content_type: 'quiz',
  content_id: quiz.id,
  exercise_type: 'exam',
  max_dpoints: 210,
  minimum_progress_percentage: 75,
  open_mode: false,
  section:,
  start_date: 2.days.ago,
  published: true,
  position: section.items.maximum(:position).to_i + 1
)
item.save!

Rails.logger.info { "Seeded question-pool exam at /learn/geo2013/items/#{item.id}" }
