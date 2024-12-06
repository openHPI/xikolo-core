# frozen_string_literal: true

class Rubric < ApplicationRecord
  scope :without_team_evaluation, -> { where(team_evaluation: false) }
  scope :ordered, -> { order(position: :asc) }
  default_scope { without_team_evaluation.ordered }

  belongs_to :peer_assessment
  has_many   :rubric_options, -> { order(points: :asc) }, dependent: :delete_all

  validates :title, presence: true

  after_create :create_team_evaluation_rubrics

  acts_as_list scope: :peer_assessment

  def max_points
    rubric_options.maximum(:points)
  end

  def create_team_evaluation_rubrics
    # create options with 1, 2, and 3 points
    if team_evaluation
      [1, 2, 3].each do |points|
        rubric_options.create points:
      end
    end
  end
end
