# frozen_string_literal: true

class Xikolo::Quiz::FreeTextQuestion < Xikolo::Quiz::Question
  service Xikolo::Quiz::Client, path: 'free_text_questions'

  attribute :case_sensitive, :boolean
end
