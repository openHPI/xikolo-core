# frozen_string_literal: true

######################################
# #######tasks##tasks##tasks###########
######################################
namespace :xikolo do
  require 'logger'
  require 'csv'

  require "#{Rails.root}/lib/tasks/rake_helper"
  include RakeHelper

  desc <<~DESC
    Exports the participants of the quiz/survey ENV['QUIZ_ID']
    - ENV['IDS_ONLY'] = 1: Only export the user_ids, no additional data, such as names or emails
    - ENV['QUESTION_IDS'] only export those users that have answered one of the given questions
    - ENV['ANSWER_IDS'] only export those users that have given one of the specified answers
    - UUIDs only, does not work for freetext answers yet.
    - Pass QUESTION_IDS and ANSWER_IDS in the following form: export_survey_participants QUESTION_IDS='f81c79f2-4010-437b-8155-7a311435a5e5 542aceca-9ebb-4fbc-8768-a0b31e90091b'
  DESC
  task export_survey_participants: :environment do
    @quiz_id = ENV.fetch('QUIZ_ID', nil)
    @ids_only = ENV.fetch('IDS_ONLY', nil)
    @question_ids = ENV.fetch('QUESTION_IDS', nil)
    @answer_ids = ENV.fetch('ANSWER_IDS', nil)

    if @quiz_id || @question_ids || @answer_ids
      # get all users that have participated in quiz
      if !@question_ids.nil?
        condition = prepare_condition @question_ids
        query = <<~SQL.squish
          select
            qq.quiz_question_id as question_id,
            s.id as submission_id,
            s.user_id as user_id
          from quiz_submission_questions as qq
          left join quiz_submissions as s on s.id = qq.quiz_submission_id
          where quiz_question_id in (#{condition});
        SQL
        filename = "survey_participants_question_#{filename_from_arg(@question_ids)}.csv"
      elsif !@answer_ids.nil?
        condition = prepare_condition @answer_ids
        query = <<~SQL.squish
          select
            qa.quiz_answer_id as answer_id,
            qq.quiz_question_id as question_id,
            s.id as submission_id,
            s.user_id as user_id
          from quiz_submission_answers as qa
          left join quiz_submission_questions as qq on qq.id = qa.quiz_submission_question_id
          left join quiz_submissions as s on s.id = qq.quiz_submission_id
          where quiz_answer_id in (#{condition});
        SQL
        filename = "survey_participants_answer_#{filename_from_arg(@answer_ids)}.csv"
      elsif !@quiz_id.nil?
        query = "select * from quiz_submissions where quiz_id='#{@quiz_id}'"
        filename = "survey_participants_quiz_#{@quiz_id}.csv"
      end
      results = ActiveRecord::Base.connection.execute(query)
      count = results.count

      init 'Export started...'

      Dir.chdir(Dir.tmpdir) do
        @filepath = File.absolute_path(filename)
        inform "CSV file will be available at: #{@filepath}"
      end

      CSV.open(@filepath, 'wb') do |csv|
        if @ids_only
          csv << ['User ID']
          results.each do |result|
            csv << [result['user_id']]
          end
        else
          csv << ['User ID', 'Email', 'Name']
          account_service = Xikolo.api(:account).value!
          results.each do |result|
            user = account_service.rel(:user).get({id: result['user_id']}).value
            csv << [result['user_id'], user['email'], user['full_name']] unless user.nil?
          end
        end
      end
      inform "#{count} participants exported."
    else
      $stdout.print "Missing one of the parameters [QUIZ_ID, QUESTION_IDS, ANSWER_IDS] \n"
    end
  end

  ######################################
  # #######helpers##helpers##############
  ######################################
  def create_logger(procedure)
    log = Logger.new "log/survey_participants_#{Time.zone.now}_.txt"
    log.info '======== START ========'
    log.info procedure
    log
  end

  def prepare_condition(input)
    ids = input.split.map {|s| "'#{s}'" }
    ids.join(', ')
  end

  def filename_from_arg(input)
    ids = input.split
    ids.join('_')
  end
end
