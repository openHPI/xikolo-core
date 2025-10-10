# frozen_string_literal: true

class Message < ApplicationRecord
  self.table_name = :messages

  belongs_to :announcement
  has_many :deliveries, dependent: :destroy

  validates :creator_id, presence: true

  scope :no_test, -> { where test: false }

  def consents=(val)
    super if val.is_a?(Array) && val.all?(String)
  end

  def language_with(user_language)
    [
      user_language,
      Xikolo.config.locales['default'],
      'en',
    ].detect(-> { translations.keys.first }) {|lang| available_in? lang }
  end

  private

  def available_in?(language)
    Xikolo.config.locales['available'].include?(language) &&
      translations.key?(language)
  end
end
