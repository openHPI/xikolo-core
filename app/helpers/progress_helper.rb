# frozen_string_literal: true

module ProgressHelper
  def calc_progress(user_points, total_points)
    return 0 if user_points.blank? || total_points.blank?

    if total_points.zero?
      0
    else
      [user_points.fdiv(total_points) * 100, 100].min.floor
    end
  end
end
