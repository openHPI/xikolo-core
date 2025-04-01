# frozen_string_literal: true

######################################
# #######tasks##tasks##tasks###########
######################################
namespace :xikolo do
  require "#{Rails.root}/app/helpers/rake_helper"
  include RakeHelper

  desc <<~DESC
    Groups the participants of a quiz/survey that have given one of the specified answers (ENV['ANSWER_IDS'])
    - UUIDs only, does not work for freetext answers yet.
    - Pass ANSWER_IDS in the following form: create_group_from_survey_answer ANSWER_IDS='2263a854-13fc-44ab-9379-99348234e579 542aceca-9ebb-4fbc-8768-a0b31e90091b'
  DESC
  task create_group_from_survey_answer: :environment do
    @answer_ids = ENV.fetch('ANSWER_IDS', nil)
    @group_name = ENV.fetch('GROUP_NAME', nil)

    if @answer_ids && @group_name
      # get all users that have answered question with certain answer
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
      results = ActiveRecord::Base.connection.execute(query)
      count = results.count

      init 'Creating group and flipper...'

      account_service = Xikolo.api(:account).value!
      account_service.rel(:groups).post({name: @group_name}).value
      account_service.rel(:group).get({id: @group_name}).value.rel(:flippers).patch({@group_name => '1'}).value

      results.each do |result|
        account_service.rel(:memberships).post({user: result['user_id'], group: @group_name}).value
      end
      inform "Group with #{count} participants and flipper created."
    else
      $stdout.print "One of the parameters [ANSWER_IDS, GROUP_NAME] is missing\n"
    end
  end

  ######################################
  # #######helpers##helpers##############
  ######################################
  def create_logger(procedure)
    log = Logger.new "log/create_group_from_survey_answer_#{Time.zone.now}_.txt"
    log.info '======== START ========'
    log.info procedure
    log
  end

  def prepare_condition(input)
    ids = input.split.map {|s| "'#{s}'" }
    ids.join(', ')
  end
end
