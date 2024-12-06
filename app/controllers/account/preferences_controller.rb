# frozen_string_literal: true

class Account::PreferencesController < Abstract::FrontendController
  include Xikolo::Account
  layout 'dashboard'

  before_action :ensure_logged_in
  include Interruptible

  VALID_BOOLEAN_PREFERENCES = %w[
    notification.email.news.announcement
    notification.email.course.announcement
    notification.email.pinboard.new_answer
    notification.email.global
    records.show_birthdate
    notification.email.stats
  ].freeze

  VALID_PREFERENCES = %w[
    ui.hints.video_player_keyhint
    ui.video.video_player_speed
    ui.video.video_player_volume
    ui.video.video_player_caption_language
    ui.video.video_player_show_captions
    ui.video.video_player_show_transcript
    ui.video.video_player_quality
    ui.video.video_player_ratio
    ui.video.video_dual_stream
  ].freeze

  def show
    preferences = Preferences.find user_id: current_user.id
    @is_teacher = current_user.allowed?('course.course.teaching_anywhere')
    Acfs.run

    @preferences = Account::PreferencesPresenter.new preferences

    @pinboard_subscriptions = Xikolo.api(:pinboard).value!
      .rel(:subscriptions).get(
        with_question: true,
        user_id: current_user.id,
        page: params[:page] || 1,
        per_page: params[:per_page] || 15
      ).value!

    @subscription_list = Admin::SubscriptionListPresenter.new(@pinboard_subscriptions)
  end

  def update
    preferences = Preferences.find user_id: current_user.id
    Acfs.run
    # !TODO: Something like this should be handled via patch update in the service

    if VALID_BOOLEAN_PREFERENCES.include?(params[:name])
      preferences.set(params[:name], params[:value] == 'true')
      preferences.save!
      head :ok, content_type: 'text/html'
    elsif VALID_PREFERENCES.include?(params[:name])
      preferences.set(params[:name], params[:value])
      preferences.save!
      head :ok, content_type: 'text/html'
    else
      head :unauthorized
    end
  end
end
