# frozen_string_literal: true

module PortalAPI
  class UsersController < BaseController
    before_action :require_authorization_header!
    before_action :require_shared_secret!
    before_action only: :update do
      allow_content_types! %w[application/vnd.openhpi.user+json;v=1.0]
    end
    before_action :require_request_body!, only: :update

    def update
      return head(:not_found) unless authorization

      replace_user_email! if params[:email].present?
      # Update user if attributes should be changed or the avatar is deleted (explicitly).
      update_user_attributes if user_params.present? || params.key?(:avatar)

      render json: serialize_user, content_type: 'application/vnd.openhpi.user+json;v=1.0'
    rescue EmailReplacementError => e
      problem_details(e.type, e.message, status: :unprocessable_entity)
    end

    def destroy
      return head(:not_found) unless authorization

      account_api.rel(:user).delete(id: authorization['user_id']).value!

      head(:no_content)
    end

    private

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end

    def authorization
      @authorization ||= account_api.rel(:authorizations).get(uid: params[:id]).value!.first
    end

    def user
      @user ||= account_api.rel(:user).get(id: authorization['user_id']).value!
    end

    def user_params
      params.permit(:display_name, :full_name, :born_at, :language, :avatar_uri)
    end

    def replace_user_email!
      @emails = user.rel(:emails).put([{address: params[:email], confirmed: true, primary: true}]).value!
    rescue Restify::UnprocessableEntity
      raise EmailReplacementError.new('The user email address could not be updated.')
    end

    def update_user_attributes
      sanitized_params = user_params.to_h.tap do |u|
        u[:avatar_uri] = params[:avatar] if params.key?(:avatar)
      end

      @updated_user = account_api.rel(:user).patch(sanitized_params, id: authorization['user_id']).value!
    rescue Restify::UnprocessableEntity
      # If this request goes wrong, we silently swallow the error
    end

    def serialize_user
      {
        id: authorization['uid'],
        display_name: @updated_user.try(:[], 'display_name') || user['display_name'],
        full_name: @updated_user.try(:[], 'full_name') || user['full_name'],
        email: @emails&.first.try(:[], 'address') || user['email'],
        born_at: @updated_user.try(:[], 'born_at') || user['born_at'],
        language: @updated_user.try(:[], 'language') || user['language'],
        avatar:,
      }
    end

    def avatar_removed?
      params.key?(:avatar) && params[:avatar].nil? && @updated_user['avatar_url'].nil?
    end

    def avatar
      return if avatar_removed?

      @updated_user.try(:[], 'avatar_url') || user['avatar_url']
    end
  end

  class EmailReplacementError < StandardError
    attr_reader :type

    def initialize(message)
      @type = 'email_update'
      super
    end
  end
end
