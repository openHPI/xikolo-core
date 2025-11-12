# frozen_string_literal: true

module PinboardService
class Stats # rubocop:disable Layout/IndentationWidth
  def initialize(course_id:, user_id: nil)
    @course_id = course_id
    @user_id = user_id
  end

  def posts
    posts_queries.sum do |query|
      query.for_user(@user_id).count(:all)
    end
  end

  def posts_last_day
    posts_queries.sum do |query|
      query.for_user(@user_id).where(created_at: last_day).count(:all)
    end
  end

  def threads
    Question
      .where(course_id: @course_id)
      .for_user(@user_id)
      .count(:all)
  end

  def threads_last_day
    Question
      .where(course_id: @course_id)
      .for_user(@user_id)
      .where(created_at: last_day)
      .count(:all)
  end

  def to_h
    {
      posts:,
      posts_last_day:,
      threads:,
      threads_last_day:,
    }
  end

  private

  def posts_queries
    [
      Question.where(course_id: @course_id),
      Answer.unscoped.select(:id).joins(:question).where(questions: {course_id: @course_id}),
      Comment.unscoped.select(:id).joins(:question).where(questions: {course_id: @course_id}),
      Comment.unscoped.select(:id).joins(:answer).joins(answer: :question).where(questions: {course_id: @course_id}),
    ]
  end

  def last_day
    @last_day ||= 1.day.ago..Time.zone.now
  end
end
end
