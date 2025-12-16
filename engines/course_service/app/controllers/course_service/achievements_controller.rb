# frozen_string_literal: true

module CourseService
class AchievementsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json
  before_action :set_locale

  def index
    respond_with Achievements.new(params[:course_id], params[:user_id])
  end

  private

  def set_locale
    I18n.locale = http_accept_language
      .preferred_language_from(Xikolo.config.locales['available'])
    response.headers['Content-Language'] = I18n.locale.to_s
  end
end
end
