# frozen_string_literal: true

class ItemStatistics
  include Draper::Decoratable

  def initialize(item)
    @item = item
  end

  def total_submissions
    results.count
  end

  def total_submissions_distinct
    results.distinct.count(:user_id)
  end

  def perfect_submissions
    results.where(dpoints: @item.max_dpoints).count
  end

  def perfect_submissions_distinct
    results.where(dpoints: @item.max_dpoints).distinct.count(:user_id)
  end

  def max_points
    @item.max_dpoints.try(:/, 10.0)
  end

  def avg_points
    results.average(:dpoints).to_f.try(:/, 10.0).round(2)
  end

  private

  def results
    @item.user_results
  end
end
