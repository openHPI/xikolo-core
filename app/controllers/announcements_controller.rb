# frozen_string_literal: true

class AnnouncementsController < Abstract::FrontendController
  require_feature 'announcements'

  def new
    authorize! 'news.announcement.create'

    @announcement = Admin::NewsForm.new(
      'show_on_homepage' => true,
      'language' => 'en', # The default announcement language is English
      'translations' => {}
    )
  end

  def edit
    authorize! 'news.announcement.update'

    @announcement = news_service.rel(:news).get(
      id: params[:id],
      embed: 'translations'
    ).then do |announcement|
      Admin::NewsForm.from_resource(announcement)
    end.value!
  end

  def create
    authorize! 'news.announcement.create'

    @announcement = Admin::NewsForm.from_params(params)

    # re-render creation form if announcement is invalid
    return render(action: :new) unless @announcement.valid?

    announcement = news_service
      .rel(:news_index)
      .post(@announcement.to_resource.merge(
              'author_id' => current_user.id
            )).value!

    announcement.rel(:email).post(email_params).value! if send_emails?

    redirect_to news_index_path
  rescue Restify::UnprocessableEntity => e
    @announcement.remote_errors e.errors

    # re-render creation form
    render(action: :new)
  end

  def update
    authorize! 'news.announcement.update'

    @announcement = Admin::NewsForm.from_params(params)
    @announcement.persisted!

    # re-render edit form if announcement is invalid
    return render(action: :edit) unless @announcement.valid?

    announcement = news_service.rel(:news).get(id: params[:id]).value!
    announcement.rel(:self).patch(@announcement.to_resource).value!

    announcement.rel(:email).post(email_params).value! if send_emails?

    add_flash_message(:success, t(:'flash.success.announcement_saved'))
    redirect_to news_index_path
  rescue Restify::UnprocessableEntity => e
    @announcement.remote_errors e.errors

    # re-render edit form
    render(action: :edit)
  end

  def destroy
    authorize! 'news.announcement.delete'

    news_service
      .rel(:news).get(id: params[:id]).value!
      .rel(:self).delete.value!

    redirect_to news_index_path
  end

  private

  def send_emails?
    (current_user.allowed?('news.announcement.send') && params[:notification] == 'send') ||
      (current_user.allowed?('news.announcement.send_test') && params[:notification] == 'test')
  end

  def email_params
    if params[:notification] == 'test'
      {test_receiver: current_user.id}
    else
      {}
    end
  end

  def news_service
    @news_service ||= Xikolo.api(:news).value!
  end
end
