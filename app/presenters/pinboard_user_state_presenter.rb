# frozen_string_literal: true

class PinboardUserStatePresenter
  def initialize(question:, user:)
    @question = question
    @user = user
  end

  def user_state_for(user_id)
    if gamification? && (level = level_for(user_id))
      user_state_icon(level)
    else
      ''
    end
  end

  def available?(user_id)
    gamification? && level_for(user_id)
  end

  private

  def user_state_icon(level)
    ActionController::Base.helpers.image_tag(user_state_path(level), title: level.title)
  end

  def user_state_path(level)
    ActionController::Base.helpers.asset_path("gamification/userstates/#{level.image}")
  end

  def level_for(user_id)
    gamification_levels.find { it.enough?(score_for(user_id)) }
  end

  def score_for(user_id)
    author_scores.fetch(user_id, 0)
  end

  def author_scores
    @author_scores ||= Gamification::Score.where(user_id: author_ids).group(:user_id).total
  end

  def gamification_levels
    @gamification_levels ||= gamification? ? Gamification::Level.all.sort : []
  end

  def author_ids
    @author_ids ||= [
      @question.user_id,
      *@question.comments.map(&:user_id),
      *@question.answers.map(&:user_id),
      *@question.answers.flat_map(&:comments).map(&:user_id),
    ].uniq
  end

  def gamification?
    @user.feature?('gamification')
  end
end
