# frozen_string_literal: true

class Xikolo::Quiz::MultipleAnswerQuestion < Xikolo::Quiz::Question
  service Xikolo::Quiz::Client, path: 'multiple_answer_questions'
end
