# frozen_string_literal: true

require 'acfs'

module Xikolo
  module Submission
    require 'xikolo/submission/client'

    require 'xikolo/submission/quiz_submission'
    require 'xikolo/submission/quiz_submission_question'
    require 'xikolo/submission/quiz_submission_answer'
    require 'xikolo/submission/quiz_submission_free_text_answer'
    require 'xikolo/submission/quiz_submission_selectable_answer'
    require 'xikolo/submission/quiz_submission_snapshot'
    require 'xikolo/submission/user_quiz_attempts'
  end
end
