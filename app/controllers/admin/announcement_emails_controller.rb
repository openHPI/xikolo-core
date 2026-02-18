# frozen_string_literal: true

class Admin::AnnouncementEmailsController < Abstract::FrontendController
  require_feature 'admin_announcements'

  def show
    # TODO: Permission!

    announcement = news_service
      .rel(:announcement)
      .get(
        params: {id: params[:id]},
        headers: {'Accept' => 'application/json'}
      ).value!
    email = announcement.rel(:message).get.value!

    @email = Admin::AnnouncementEmailPresenter.new(announcement, email)
  end

  def new
    announcement = news_service.rel(:announcement).get({id: UUID4(params[:id]).to_s}).value!

    @announcement_email = Admin::AnnouncementEmailForm.from_resource(
      announcement.merge('language' => Xikolo.config.locales['default'])
    )
  end

  def create
    @announcement_email = Admin::AnnouncementEmailForm.from_params(params)

    # Re-render creation form if announcement is invalid
    return render(action: :new, status: :unprocessable_entity) unless @announcement_email.valid?

    announcement = news_service.rel(:announcement).get({id: UUID4(params[:id]).to_s}).value!
    announcement.rel(:messages).post(
      @announcement_email.to_resource.merge('creator_id' => current_user.id)
    ).value!

    redirect_to admin_announcements_path, status: :see_other
  rescue Restify::UnprocessableEntity => e
    @announcement_email.remote_errors e.errors

    # Re-render creation form
    render(action: :new, status: :unprocessable_entity)
  end

  private

  def news_service
    @news_service ||= Xikolo.api(:news).value!
  end
end
