# frozen_string_literal: true

##
# Select the best text from a hash of localized variants.
#
# The choice is made based on what locales are enabled on the platform,
# what variants are available and which locale is active right now.
#
class Translations
  def initialize(hash, locale_preference: [])
    if hash.is_a?(String)
      @hash = {'en' => hash}
      return
    end

    @hash = hash&.stringify_keys || {}
    @locales = locale_preference
  end

  def to_s
    @hash[best_locale] || ''
  end

  def empty?
    @hash.empty?
  end

  private

  def best_locale
    @best_locale ||= (@locales.presence || [
      I18n.locale.to_s,
      Xikolo.config.locales['default'],
      'en',
    ]).detect(-> { @hash.keys.first }) {|lang| @hash.key? lang }
  end
end
