# frozen_string_literal: true

module NewsService
class ReadState < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :read_states

  # includes a news_id and the user who has seen this news
  belongs_to :news
end
end
