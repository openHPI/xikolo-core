# frozen_string_literal: true

class Xikolo::Quiz::EssayQuestion < Xikolo::Quiz::Question
  service Xikolo::Quiz::Client, path: 'essay_questions'
end
