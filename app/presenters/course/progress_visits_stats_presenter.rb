# frozen_string_literal: true

class Course::ProgressVisitsStatsPresenter < PrivatePresenter
  def total_count
    @total
  end

  def user_count
    @user
  end

  def user_percentage
    @percentage
  end
end
