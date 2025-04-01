# frozen_string_literal: true

class Account::PolicyPresenter
  extend Forwardable
  extend RestifyForwardable

  def_restify_delegators :@policy, :version

  def initialize(policy)
    @policy = policy
  end

  def url
    [
      I18n.locale.to_s,
      Xikolo.config.locales['default'],
      *Xikolo.config.locales['available'],
    ].each do |locale|
      url_map = @policy.fetch('url')
      return url_map[locale] if url_map.key?(locale)
    end

    nil
  end
end
