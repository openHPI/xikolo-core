# frozen_string_literal: true

class Delivery < ApplicationRecord
  self.table_name = :deliveries

  belongs_to :message

  has_one :announcement, through: :message

  def sent?
    sent_at.present?
  end
end
