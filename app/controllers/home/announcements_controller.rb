# frozen_string_literal: true

class Home::AnnouncementsController < Abstract::FrontendController
  include Interruptible

  require_feature 'announcements'

  def index
    get_params = {
      published: !current_user.allowed?('news.announcement.show'),
      language: I18n.locale,
    }
    get_params[:user_id] = current_user.id if current_user.logged_in?

    @posts = Xikolo.api(:news).value!.rel(:posts).get(
      get_params
    ).value!.map do |post|
      AnnouncementPresenter.create post
    end

    set_meta_tags(title: t(:'announcements.title', brand: Xikolo.config.site_name))
  end
end
