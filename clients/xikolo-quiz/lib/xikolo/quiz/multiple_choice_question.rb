# frozen_string_literal: true

class Xikolo::Quiz::MultipleChoiceQuestion < Xikolo::Quiz::Question
  service Xikolo::Quiz::Client, path: 'multiple_choice_questions'
end
