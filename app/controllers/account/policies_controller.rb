# frozen_string_literal: true

module Account
  class PoliciesController < Abstract::FrontendController
    before_action :ensure_logged_in

    def show
      @policy = PolicyPresenter.new(policy)
    end

    def update
      user = account_api.rel(:user).get({id: current_user.id}).value!
      user.rel(:self).patch({accepted_policy_version: policy.fetch('version')})

      redirect_to redirect_url
    end

    private

    def policy_params
      params.require :p
    end

    def policy
      policies = account_api.rel(:policies).get.value!
      return policies.first if policies.present?

      nil
    end

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
