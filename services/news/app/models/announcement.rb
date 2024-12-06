# frozen_string_literal: true

class Announcement < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :author_id, presence: true
  validate :valid_translations

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

  TRANSLATION_KEYS = %w[subject content].sort.freeze

  def valid_translations
    # move array out of loop
    return if translations.all? do |_, attributes|
      attributes.keys.sort == TRANSLATION_KEYS &&
      TRANSLATION_KEYS.all? {|key| attributes.fetch(key) }
    end

    errors.add :translations, 'invalid'
  end
end
