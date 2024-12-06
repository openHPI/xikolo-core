# frozen_string_literal: true

class Home::HomeController < Abstract::FrontendController
  prepend_view_path "brand/#{Xikolo.brand}/views"

  include Interruptible

  def index
    @posts = posts

    if Rails.application.config.respond_to?(:homepage_course_loader)
      @categories = Rails.application.config.homepage_course_loader.call
    end

    if Rails.application.config.respond_to?(:homepage_topics_loader)
      @topics = Rails.application.config.homepage_topics_loader.call
    end

    if Rails.application.config.respond_to?(:homepage_video_loader)
      @homepage_video = Rails.application.config.homepage_video_loader.call
    end
  end

  private

  def posts
    return [] unless feature?('announcements')
    return [] unless Xikolo.api?(:news)

    Xikolo.api(:news).value!.rel(:news_index).get(
      {
        global: true,
        per_page: 4,
        published: true,
        only_homepage: true,
        language: I18n.locale,
      },
      {headers: {'Accept' => 'application/msgpack, application/json'}}
    ).value!.map do |post|
      AnnouncementPresenter.create post
    end
  rescue Restify::NetworkError, Restify::ServerError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    []
  end
end
