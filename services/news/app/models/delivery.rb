# frozen_string_literal: true

class Delivery < ApplicationRecord
  belongs_to :message

  has_one :announcement, through: :message

  def sent?
    sent_at.present?
  end
end
