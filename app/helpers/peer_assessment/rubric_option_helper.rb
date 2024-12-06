# frozen_string_literal: true

module PeerAssessment::RubricOptionHelper
  def divergence_indicator(review, ta_review, option_index, current_option)
    student_option = review.optionIDs[option_index]
    ta_option      = ta_review.optionIDs[option_index]
    match = nil

    if student_option == ta_option
      if ta_option == current_option.id
        match = 'match'
      end
    elsif ta_option == current_option.id
      match = 'ta_answer'
    elsif student_option == current_option.id
      match = 'your_answer'
    end

    if match
      return tag.div(class: "comparison-indicator #{match}") do
        concat(I18n.t(:"peer_assessment.training.match_type.#{match}"))
      end
    end

    ''
  end
end
