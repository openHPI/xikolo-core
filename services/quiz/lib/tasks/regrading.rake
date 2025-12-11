# frozen_string_literal: true

namespace :regrading do
  require 'logger'

  desc <<-DESC.gsub(/\s+/, ' ')
  Select specific answer for all submitted questions and recalculate points
  - just check the results, do not update: ENV['DRY']=1
  DESC
  task select_answer_for_all: :environment do
    # rake regrading:select_answer_for_all RAILS_ENV=development
    # ANSWER_ID='830f7258-0d29-420b-96f1-d4bb022c00ec' DRY=1
    QuizService::Regrading::SelectAnswerForAll.new(
      answer = Answer.find(ENV.fetch('ANSWER_ID', nil)),
      dry: ENV['DRY'] == '1'
    ).tap do |regrading|
      regrading.logger = Logger.new($stdout)
    end.run!

    suggest_course_update answer.question.quiz_id
  end

  desc <<-DESC.gsub(/\s+/, ' ')
  Remove answer from question and recalculate points from remaining answers
  - just check the results, do not update: ENV['DRY']=1
  DESC
  task remove_answer: :environment do
    QuizService::Regrading::RemoveAnswer.new(
      answer = QuizService::Answer.find(ENV.fetch('ANSWER_ID', nil)),
      dry: ENV['DRY'] == '1'
    ).tap do |regrading|
      regrading.logger = Logger.new($stdout)
    end.run!

    suggest_course_update answer.question.quiz_id
  end

  desc <<-DESC.gsub(/\s+/, ' ')
  Reset points after adding additional freetext answers or changing correctness of
  answer options in web frontend; parameters: QUESTION_ID=id
  - just check the results, do not update: ENV['DRY']=1
  DESC
  task update_question: :environment do
    QuizService::Regrading::UpdateQuestion.new(
      question = QuizService::Question.find(ENV.fetch('QUESTION_ID', nil)),
      dry: ENV['DRY'] == '1'
    ).tap do |regrading|
      regrading.logger = Logger.new($stdout)
    end.run!

    suggest_course_update question.quiz_id
  end

  desc <<-DESC.gsub(/\s+/, ' ')
  Reset points after changing points distribution in a quiz; parameters: QUIZ_ID=id
  - just check the results, do not update: ENV['DRY']=1
  DESC
  task update_all_questions: :environment do
    QuizService::Regrading::UpdateAllQuestions.new(
      Quiz.find(ENV.fetch('QUIZ_ID', nil)),
      dry: ENV['DRY'] == '1'
    ).tap do |regrading|
      regrading.logger = Logger.new($stdout)
    end.run!

    suggest_course_update ENV.fetch('QUIZ_ID', nil)
  end

  desc <<-DESC.gsub(/\s+/, ' ')
  Regrade question ENV['QUESTION_ID'] provide all users with full points
  regardless of their answers.
  - just check the results, do not update: ENV['DRY']=1
  DESC
  task jackpot: :environment do
    QuizService::Regrading::Jackpot.new(
      question = Question.find(ENV.fetch('QUESTION_ID', nil)),
      dry: ENV['DRY'] == '1'
    ).tap do |regrading|
      regrading.logger = Logger.new($stdout)
    end.run!

    suggest_course_update question.quiz_id
  end

  desc <<-DESC.gsub(/\s+/, ' ')
  Just upgrade the course results if a regrading has been done directly in the database.
  Requires the quiz id of the question that has been regraded ENV['QUIZ_ID']
  DESC
  task just_update_course: :environment do
    QuizService::Regrading::UpdateCourseResults.new(
      Logger.new($stdout),
      ENV.fetch('QUIZ_ID', nil)
    ).run!
  end

  def suggest_course_update(quiz_id)
    $stdout.print "You still need to update the course results by calling: \n"
    $stdout.print "xikolo-quiz rake regrading:just_update_course QUIZ_ID=#{quiz_id} \n"
    $stdout.print "If you have more answers for this quiz to edit, please do that first. \n"
  end
end
