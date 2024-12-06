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
    Msgr.publish announcement.decorate.as_event.tap {|data|
      if test_recipient
        data[:test] = true
        data[:receiver_id] = test_recipient
      end
    }, to: 'xikolo.news.announcement.create'
  end
end
