# frozen_string_literal: true

class API::RootController < API::BaseController
  include Caching

  respond_to :json

  def index
    expires_in 5.minutes, public: true

    respond_with routes
  end

  private
  def routes
    # Update cache key version when updating the routes hash
    caching 'root/routes/v6' do
      {
        authorization_url: authorization_rfc6570,
        authorizations_url: authorizations_rfc6570,
        context_url: context_rfc6570,
        contexts_url: contexts_rfc6570,
        email_suspensions_url: email_suspension_rfc6570,
        email_url: email_rfc6570,
        grant_url: grant_rfc6570,
        grants_url: grants_rfc6570,
        group_url: group_rfc6570,
        groups_url: groups_rfc6570,
        membership_url: membership_rfc6570,
        memberships_url: memberships_rfc6570,
        password_reset_url: password_reset_rfc6570,
        password_resets_url: password_resets_rfc6570,
        policies_url: policies_rfc6570,
        role_url: role_rfc6570,
        roles_url: roles_rfc6570,
        session_url: session_rfc6570,
        sessions_url: sessions_rfc6570,
        statistics_url: statistic_rfc6570,
        system_info_url: system_info_rfc6570,
        token_url: token_rfc6570,
        tokens_url: tokens_rfc6570,
        treatment_url: treatment_rfc6570,
        treatments_url: treatments_rfc6570,
        user_url: user_rfc6570,
        user_ban_url: user_ban_rfc6570,
        users_url: users_rfc6570,
      }
    end
  end
end
