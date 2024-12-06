# frozen_string_literal: true

class AlternativeSectionProgress
  def initialize(parent:, user:)
    @parent = parent
    @user_id = user
  end

  ##
  # Set the best alternative to be considered for the course
  # progress calculation.
  def set_best_alternative!
    ActiveRecord::Base.transaction do
      relevant_progresses.lock.each do |progress|
        if progress.section_id == best_alternative.section_id
          progress.update!(alternative_progress_for: @parent.id)
        else
          progress.update!(alternative_progress_for: nil)
        end
      end
    end
  end

  ##
  # Rank all relevant child sections (alternatives) to determine
  # the best alternative to be considered for the course progress.
  # Sample ranking for various alternative sections:
  # rank | pts % |  pts n  | visits %  | visits n
  #   1  |  80%  |   50    |    100%   | --
  #   2  |  80%  |   50    |     80%   | --
  #   3  |  80%  |   40    |     80%   | 30
  #   4  |  80%  |   40    |     80%   | 25
  #   5  |   0%  |  -40    |     70%   | --
  #   6  |   0%  |  -50    |     70%   | -25
  #   7  |   0%  |  -50    |     70%   | -30
  def best_alternative
    # This is calculated in memory, which should be fine for the limited
    # number of alternative sections.
    @best_alternative ||=
      if relevant_progresses.any?
        # If the user has progress in the child section(s) of an alternative
        # section, select the best alternative to be considered based on the
        # ranking (see above).
        relevant_progresses.max_by do |progress|
          goals = progress.section.goals(@user_id)
          [
            progress.points_percentage,
            progress.points_percentage.zero? ? -goals.max_dpoints : goals.max_dpoints,
            progress.visits_percentage,
            progress.visits_percentage.zero? ? -goals.max_visits : goals.max_visits,
          ]
        end
      else
        # If the user does not have progress in the child section(s), select
        # the the best section for the user in terms of minimal penalty (points
        # and visits missing). Do not create / persist any section progress.
        SectionProgress.new(
          section: @parent.children.published.min_by do |section|
            goals = section.goals(@user_id)
            [goals.max_dpoints, goals.max_visits]
          end,
          user_id: @user_id
        )
      end
  end

  private

  def relevant_progresses
    @relevant_progresses ||= SectionProgress.where(
      section: @parent.children.published,
      user_id: @user_id
    )
  end
end
