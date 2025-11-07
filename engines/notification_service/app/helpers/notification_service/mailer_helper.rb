# frozen_string_literal: true

module NotificationService
module MailerHelper # rubocop:disable Layout/IndentationWidth
  def locale_string_from(hash)
    hash = ActiveSupport::HashWithIndifferentAccess.new hash

    hash[I18n.locale] ||
      hash[Xikolo.config.locales['default']] ||
      hash.values.compact.first
  end

  def get_language(language)
    return language if Xikolo.config.locales['available'].include? language

    Xikolo.config.locales['default']
  end
end
end
