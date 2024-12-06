# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmissionSelectableAnswer < Xikolo::Submission::QuizSubmissionAnswer
    service Xikolo::Submission::Client, path: 'quiz_submission_selectable_answers'
  end
end
