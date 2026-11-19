# frozen_string_literal: true

module Cmi5
  class TokensController < Cmi5::ApplicationController
    AUTH_TOKEN_TTL = 1.day

    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      Cmi5::Item.find(params[:id])
      item = CourseService::Item.find_by!(
        content_type: 'cmi5',
        content_id: params[:id]
      )
      return unauthorized! unless active_enrollment?(item)

      token = generate_auth_token

      render json: {'auth-token': encoded_auth_token(token)}, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: {error: 'Not Found'}, status: :not_found
    end

    private

    def active_enrollment?(item)
      CourseService::Enrollment.active.exists?(
        course_id: item.course_id,
        user_id: current_user.id
      )
    end

    def generate_auth_token
      self.class.verifier.generate(
        {
          item_id: params[:id],
        },
        purpose: :cmi5_reporting,
        expires_in: AUTH_TOKEN_TTL
      )
    end

    def encoded_auth_token(token)
      Base64.strict_encode64("#{token}:")
    end
  end
end
