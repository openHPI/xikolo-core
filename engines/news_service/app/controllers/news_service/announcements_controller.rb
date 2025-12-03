# frozen_string_literal: true

module NewsService
class AnnouncementsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # This returns (targeted) announcements for admins only, these are not
  # displayed to regular users.
  def index
    respond_with Announcement.order(created_at: :desc)
  end

  def show
    respond_with Announcement.find params[:id]
  end

  def create
    announcement = Announcement.create announcement_params

    respond_with announcement, location: nil
  end

  def decoration_context
    @decoration_context ||= params.permit(:language)
  end

  private

  def announcement_params
    params.permit(:author_id, translations: translation_structure)
  end

  def translation_structure
    Xikolo.config.locales['available'].index_with do |_locale|
      %i[subject content]
    end
  end
end
end
