# frozen_string_literal: true

######################################
# #######tasks##tasks##tasks###########
######################################
namespace :submission do
  require 'logger'

  require "#{Rails.root}/lib/tasks/rake_helper"
  include RakeHelper

  desc <<~DESC
    Removes dead submissions (where actual quizzes have been deleted).
    - just check the results, do not delete: ENV['DRY']=1
  DESC
  task remove_dead: :environment do
    # rake submission:remove_dead DRY=1
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @dry = ENV.fetch('DRY', nil)

    init 'Deleting dead submissions...'

    # fetch quiz ids
    inform 'Fetching quiz ids...'
    quiz_ids = QuizService::Quiz.ids

    if quiz_ids.empty?
      inform 'No quizzes. Nothing to do.'
      exit 0
    end

    inform "#{quiz_ids.length} quizzes to consider."

    count = 0
    sub_count = 0
    num_submissions = QuizService::QuizSubmission.where.not(quiz_id: quiz_ids).count

    inform "Checking #{num_submissions} submissions for living dead..."

    QuizService::QuizSubmission.where.not(quiz_id: quiz_ids).find_each do |submission|
      sub_count += 1
      if sub_count % 10 == 0
        inform "#{sub_count} of #{num_submissions} checked (#{(sub_count.to_f / num_submissions * 10.0).round(1)}%)"
      end
      next unless quiz_ids.include? submission.quiz_id

      inform "Deleting quiz submission #{submission.id} (user: #{submission.user_id} / quiz: #{submission.quiz_id})"
      submission.quiz_submission_questions.each do |question|
        question.destroy unless @dry
      end
      if submission.quiz_submission_snapshot && !@dry
        submission.quiz_submission_snapshot.destroy
      end
      submission.destroy unless @dry
      count += 1
    end
    inform "#{count} dead submissions deleted."
  end

  ######################################
  # #######helpers##helpers##############
  ######################################
  def create_logger(procedure)
    log = Logger.new 'log/remove_dead.txt'
    log.info '======== START ========'
    log.info procedure
    log
  end
end
