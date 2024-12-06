# frozen_string_literal: true

class Admin::AnnouncementsListPresenter
  extend Forwardable

  def initialize(announcements)
    @announcements = announcements
  end

  def_delegators :all, :each, :any?

  def pagination
    RestifyPaginationCollection.new(@announcements)
  end

  private

  def all
    @all ||= @announcements.map do |res|
      Admin::AnnouncementPresenter.new res
    end
  end
end
