# frozen_string_literal: true

class ReadState < ApplicationRecord
  # includes a news_id and the user who has seen this news
  belongs_to :news
end
