# frozen_string_literal: true

class Alert < ApplicationRecord
  scope :by_publication_date, lambda {
    order Arel.sql('publish_at IS NOT NULL'), 'publish_at DESC'
  }

  scope :published, lambda {
    now = Time.zone.now
    where.not(publish_at: nil)
      .where(publish_at: ...now)
      .where('publish_until IS NULL OR publish_until > ?', now)
  }

  validate :default_translation_exists

  class << self
    def default_locale
      Xikolo.config.locales['default']
    end
  end

  def try_translation(locale)
    locale = self.class.default_locale unless translations.key?(locale)
    Translation.new(locale, translations[locale])
  end

  private

  def default_translation_exists
    return if translations[self.class.default_locale]

    errors.add :translations, 'default_translation_missing'
  end

  class Translation
    def initialize(locale, data)
      @locale = locale
      @data = data
    end

    attr_reader :locale

    def title
      @data['title']
    end

    def text
      @data['text']
    end
  end
end
