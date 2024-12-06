# frozen_string_literal: true

class Course::ProgressExerciseStatsPresenter < PrivatePresenter
  include ProgressHelper

  def available?
    @total_exercises && (@total_exercises > 0)
  end

  attr_reader :total_exercises, :submitted_exercises

  def total_points
    @max_points.round(2)
  end

  def submitted_points
    @submitted_points.round(2)
  end

  def my_progress
    calc_progress(submitted_points, total_points)
  end

  def items
    (@items || []).map do |i|
      item = Xikolo::Course::Item.new(i)
      ItemPresenter.for(item, course: @course, user: @user)
    end
  end
end
