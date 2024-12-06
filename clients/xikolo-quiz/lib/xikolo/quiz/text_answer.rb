# frozen_string_literal: true

class Xikolo::Quiz::TextAnswer < Xikolo::Quiz::Answer
  service Xikolo::Quiz::Client, path: 'text_answers'
end
