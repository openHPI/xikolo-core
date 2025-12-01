# frozen_string_literal: true

class Email < ApplicationRecord
  self.table_name = 'news_emails'

  belongs_to :announcement,
    class_name: 'News',
    foreign_key: 'news_id',
    inverse_of: :emails

  after_commit :schedule_sending!, on: :create

  private

  def schedule_sending!
    if announcement&.publish_at&.future?
      CourseAnnouncementJob.set(wait_until: announcement.publish_at).perform_later(id)
    else
      CourseAnnouncementJob.perform_later(id)
    end
  end
end
