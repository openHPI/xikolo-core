# frozen_string_literal: true

class Xikolo::Quiz::FreeTextAnswer < Xikolo::Quiz::Answer
  service Xikolo::Quiz::Client, path: 'free_text_answers'
end
