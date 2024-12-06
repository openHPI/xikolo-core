# frozen_string_literal: true

class GamificationConsumer < Msgr::Consumer
  # In general, there are two ways to deactivate a rule:
  # 1. Remove or comment the rule in the config file
  #    Then, check if the rule is active/exists: rule_active?(:attended_section).
  #    Be careful as some rules serve as the basis for other rules, also for the badges.
  #    If you choose this option, side effects may occur.
  # 2. Award 0 points for the rule
  #    This only affects the rule at hand. No side effects will be caused for other rules.

  ##
  # COURSE-RELATED ROUTES

  def result_create
    return unless Xikolo.config.gamification['enabled']

    # Make sure we have a rule matching the exercise type
    case payload.fetch(:exercise_type)
      when 'main'
        Gamification::Rules::Course::TakeExam.new(payload).create_score!
      when 'selftest'
        Gamification::Rules::Course::TakeSelftest.new(payload).create_score!
    end
  end

  def visit_create
    return unless Xikolo.config.gamification['enabled']

    Gamification::Rules::Course::VisitedItem.new(payload).create_score!
  end

  ##
  # PINBOARD-RELATED ROUTES

  def vote_create
    return unless Xikolo.config.gamification['enabled']

    # Make sure we have a rule for the votable element
    case payload.fetch(:votable_type)
      when 'Answer'
        Gamification::Rules::Pinboard::UpvoteAnswer.new(payload).create_score!
      when 'Question'
        Gamification::Rules::Pinboard::UpvoteQuestion.new(payload).create_score!
    end
  end

  def comment_create
    return unless Xikolo.config.gamification['enabled']

    Gamification::Rules::Pinboard::CreateComment.new(payload).create_score!
  end

  def question_create
    return unless Xikolo.config.gamification['enabled']

    Gamification::Rules::Pinboard::CreateQuestion.new(payload).create_score!
  end

  def answer_accepted
    return unless Xikolo.config.gamification['enabled']

    Gamification::Rules::Pinboard::AcceptedAnswer.new(payload).create_score!
  end

  def answer_create
    return unless Xikolo.config.gamification['enabled']

    Gamification::Rules::Pinboard::AnsweredQuestion.new(payload).create_score!
  end
end
