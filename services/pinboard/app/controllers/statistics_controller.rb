# frozen_string_literal: true

class StatisticsController < ApplicationController
  responders Responders::HttpCacheResponder

  respond_to :json

  def index
    stats = []
    if params[:course_id]
      members = []
      if params[:for_teaching_team] == 'true'
        members = teaching_team_members
      elsif params[:most_active].present?
        if params[:include_teaching_team].present?
          members = most_active_users(Integer(params[:most_active]), with_teaching_team: params[:include_teaching_team])
        else
          members = most_active_users(Integer(params[:most_active]))
        end
      end
      stats = stats_for_users(members)
    end

    respond_with stats
  end

  def show
    respond_with Stats.new(
      course_id: params[:id],
      user_id: params[:user_id]
    ).to_h
  end

  private

  def stats_for_users(members)
    members.map do |member|
      Stats.new(
        course_id: params[:course_id],
        user_id: member['id']
      ).to_h.merge(user: member.slice('id', 'name'))
    end
  end

  def most_active_users(count, with_teaching_team: false)
    unless with_teaching_team
      teaching_team = teaching_team_members
      count += teaching_team.length
    end
    sql = <<~SQL.squish
      SELECT user_id, COUNT(user_id) AS count FROM
        (SELECT user_id FROM questions WHERE course_id = :course_id AND learning_room_id IS NULL
        UNION ALL SELECT a.user_id FROM answers a JOIN questions q ON a.question_id = q.id WHERE q.course_id = :course_id AND q.learning_room_id IS NULL
        UNION ALL SELECT c.user_id FROM comments c JOIN questions q ON c.commentable_id = q.id WHERE c.commentable_type = 'Question' AND q.course_id = :course_id AND q.learning_room_id IS NULL
        UNION ALL SELECT c.user_id FROM comments c JOIN answers a ON c.commentable_id = a.id JOIN questions q ON a.question_id = q.id WHERE c.commentable_type = 'Answer' AND q.course_id = :course_id AND q.learning_room_id IS NULL) x
        GROUP BY user_id ORDER BY count DESC LIMIT :cnt;
    SQL

    sql = ApplicationRecord.sanitize_sql_array([sql, {course_id: course['id'], cnt: count}])
    records = ActiveRecord::Base.connection.execute(sql).values
    users = records.map do |record|
      account_api.rel(:user).get({id: record[0]}).value!
    end
    users -= teaching_team unless with_teaching_team
    users
  end

  def teaching_team_members
    course['special_groups'].flat_map do |group|
      group_name = ['course', course['course_code'], group].join '.'
      account_api.rel(:group).get({id: group_name}).value!.rel(:members).get.value!
    end
  end

  def course
    @course ||= ::Xikolo.api(:course).value!.rel(:course).get({id: params[:course_id]}).value!
  end

  def account_api
    @account_api ||= ::Xikolo.api(:account).value!
  end
end
