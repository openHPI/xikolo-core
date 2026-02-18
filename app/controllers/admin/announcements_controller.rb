# frozen_string_literal: true

class Admin::AnnouncementsController < Abstract::FrontendController
  require_feature 'admin_announcements'

  def index
    authorize! 'news.announcement.create'

    announcements = news_service
      .rel(:announcements)
      .get(headers: {'Accept' => 'application/json'})
      .value!

    @drafts = Admin::AnnouncementsListPresenter.new(
      announcements.select do |announcement|
        announcement['publication_channels'].empty?
      end
    )

    @published = Admin::AnnouncementsListPresenter.new(
      announcements.reject do |announcement|
        announcement['publication_channels'].empty?
      end
    )
  end

  def new
    authorize! 'news.announcement.create'

    @announcement = Admin::AnnouncementForm.new(
      'language' => Xikolo.config.locales['default']
    )
  end

  def edit
    authorize! 'news.announcement.update'

    @announcement = news_service.rel(:announcement).get({id: params[:id]})
      .then {|announcement| Admin::AnnouncementForm.from_resource(announcement) }
      .value!
  end

  def create
    authorize! 'news.announcement.create'

    @announcement = Admin::AnnouncementForm.from_params(params)

    # Re-render creation form if announcement is invalid
    return render(action: :new, status: :unprocessable_entity) unless @announcement.valid?

    news_service
      .rel(:announcements)
      .post(@announcement.to_resource.merge('author_id' => current_user.id))
      .value!

    redirect_to admin_announcements_path, status: :see_other
  rescue Restify::UnprocessableEntity => e
    @announcement.remote_errors e.errors

    # Re-render creation form
    render(action: :new, status: :unprocessable_entity)
  end

  def update
    authorize! 'news.announcement.update'

    @announcement = Admin::AnnouncementForm.from_params(params)
    @announcement.persisted!

    # Re-render edit form if announcement is invalid
    return render(action: :edit, status: :unprocessable_entity) unless @announcement.valid?

    announcement = news_service.rel(:announcement).get({id: UUID4(params[:id]).to_s}).value!
    announcement.rel(:self).patch(@announcement.to_resource).value!

    add_flash_message(:success, t(:'flash.success.announcement_saved'))
    redirect_to admin_announcements_path, status: :see_other
  rescue Restify::UnprocessableEntity => e
    @announcement.remote_errors e.errors

    # Re-render edit form
    render(action: :edit, status: :unprocessable_entity)
  end

  private

  def news_service
    @news_service ||= Xikolo.api(:news).value!
  end
end
