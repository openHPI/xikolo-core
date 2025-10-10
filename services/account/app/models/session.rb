# frozen_string_literal: true

class Session < ApplicationRecord
  self.table_name = :sessions

  include SessionInterrupt

  belongs_to :user
  belongs_to :masquerade, class_name: 'User', optional: true, inverse_of: false

  after_commit(on: :create) { notify(:create) }
  after_commit(on: :destroy) { notify(:destroy) }

  class << self
    def resolve(param)
      return param if param.is_a?(self)

      case param
        when 'anonymous'
          anonymous
        when /\Atoken=([a-f0-9]{64})\z/
          TokenSession.new \
            token: Regexp.last_match(1),
            user: Token.where(token: Regexp.last_match(1)).take!.owner
        else
          find UUID4.try_convert(param.to_s).to_s
      end
    end

    def anonymous
      AnonymousSession.new id: 'anonymous', user: User.anonymous
    end

    def active
      where deleted: false
    end
  end

  def notify(action)
    Msgr.publish(decorate.as_event, to: "xikolo.account.session.#{action}")
  end

  def masquerade!(user)
    update! masquerade: user
  end

  def demasquerade!
    update! masquerade: nil
  end

  def masqueraded?
    self[:masquerade_id].present?
  end

  def effective_user
    masqueraded? ? masquerade : user
  end

  def effective_user_id
    masqueraded? ? masquerade_id : user_id
  end

  def anonymous?
    user ? user.anonymous? : false
  end

  def permissions(context:)
    Role.permissions principal: effective_user, context:
  end

  def features(context:)
    Feature.lookup owner: effective_user, context:
  end

  def access!
    return if masqueraded?
    return if access_at == Time.zone.today

    update_column :access_at, Time.zone.today # rubocop:disable Rails/SkipsModelValidations
    user.access!
  end
end

class AnonymousSession < Session
  def to_param
    'anonymous'
  end

  def interrupt?
    false
  end

  def interrupts
    []
  end

  def access!; end
end

class TokenSession < Session
  attr_accessor :token

  def to_param
    "token=#{token}"
  end

  def access!; end
end
