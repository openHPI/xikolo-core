# frozen_string_literal: true

class Admin::AnnouncementPresenter
  def initialize(resource)
    @resource = resource
  end

  include Rails.application.routes.url_helpers

  def author_id
    @resource['author_id']
  end

  def created_at
    I18n.l Time.zone.parse(@resource['created_at']), format: :short_datetime
  end

  def title
    @resource['title']
  end

  def blog?
    @resource['publication_channels'].key? 'blog'
  end

  def blog_path
    news_index_path anchor: "post_#{@resource['id']}"
  end

  def email?
    @resource['publication_channels'].key? 'email'
  end

  def email_status
    'sending'
  end

  def email_create_path
    new_admin_announcement_email_path @resource['id']
  end

  def email_stats_path
    admin_announcement_email_path @resource['id']
  end
end
