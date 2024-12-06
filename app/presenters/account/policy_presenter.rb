# frozen_string_literal: true

class Account::PolicyPresenter
  extend Forwardable

  def_delegators :@policy, :version

  def initialize(policy)
    @policy = policy
  end

  def url
    [
      I18n.locale.to_s,
      Xikolo.config.locales['default'],
      *Xikolo.config.locales['available'],
    ].each do |locale|
      if @policy.url.key? locale
        return @policy.url[locale]
      end
    end
    nil
  end
end
