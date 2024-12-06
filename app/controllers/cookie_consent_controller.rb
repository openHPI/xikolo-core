# frozen_string_literal: true

class CookieConsentController < ApplicationController
  def create
    return head :no_content if params[:consent_name].blank?

    consent_cookie = ConsentCookie.new(cookies)
    if params[:accept].present?
      consent_cookie.accept(params[:consent_name])
    else
      consent_cookie.decline(params[:consent_name])
    end

    redirect_back fallback_location: root_url
  end
end
