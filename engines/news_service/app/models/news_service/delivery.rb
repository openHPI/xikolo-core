# frozen_string_literal: true

module NewsService
class Delivery < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :deliveries

  belongs_to :message

  has_one :announcement, through: :message

  def sent?
    sent_at.present?
  end
end
end
