# frozen_string_literal: true

module IcalHelper
  # Build a hash from token and userID., can handle a user id or a user object
  def ical_hash(user)
    user_id = user.is_a?(String) ? user : user.id
    token = Xikolo::Account::Token.create(user_id:)
    Acfs.run
    dig = Digest::SHA256.hexdigest [user_id, token.token].join
    dig[10..20]
  end

  def ical_url(user, full_path: false)
    path = "ical.ical?u=#{UUID(user.id).to_param}&h=#{ical_hash(user)}"
    if full_path
      Xikolo.base_url.join(path).to_s
    else
      "/#{path}"
    end
  end
end
