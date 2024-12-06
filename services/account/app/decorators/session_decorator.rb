# frozen_string_literal: true

class SessionDecorator < ApplicationDecorator
  delegate_all

  DEFAULT = %i[
    id
    user_id
    user_agent
    masqueraded
  ].freeze

  LINKS = %i[
    self_url
    user_url
  ].freeze

  def as_json(opts = {})
    @opts = opts

    json = {
      'id' => id,
      'self_url' => self_url,
    }

    if user
      json.merge! \
        'user_id' => user_id,
        'user_url' => user_url,
        'user_agent' => user_agent,
        'masqueraded' => masqueraded?,
        'interrupt' => interrupt?,
        'interrupts' => interrupts

      json['tokens_url'] = tokens_url unless anonymous?
      json['masquerade_url'] = masquerade_url if !anonymous? && !token?
    end

    json['user']        = user        if embed?(:user)
    json['features']    = features    if embed?(:features)
    json['permissions'] = permissions if embed?(:permissions)

    json.as_json(opts)
  end

  def as_event(**opts)
    @opts = opts

    {
      'id' => id,
      'user_id' => user_id,
      'user_agent' => user_agent,
      'masqueraded' => masqueraded?,
    }
  end

  private

  def user
    object.effective_user.try :decorate
  end

  def user_id
    object.effective_user_id
  end

  def permissions
    object.permissions context: ctx
  end

  def features
    FeaturesDecorator.new object.features context: ctx
  end

  def self_url
    h.session_url to_param
  end

  def user_url
    h.user_url user_id
  end

  def tokens_url
    h.tokens_url user_id:
  end

  def masquerade_url
    h.session_masquerade_url self
  end

  def embed?(obj)
    @opts.key?(:embed) && @opts[:embed].include?(obj.to_s)
  end

  def ctx
    @ctx ||= begin
      ctx = @opts.fetch(:context) { Context.root }
      ctx = ctx.call if ctx.respond_to?(:call)
      ctx
    end
  end

  def token?
    respond_to? :token
  end
end
