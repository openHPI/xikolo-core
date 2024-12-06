# frozen_string_literal: true

module Helpdesk
  class Ticket < ::ApplicationRecord
    require 'uri'

    validates :report, :topic, :language, presence: true
    validates :title, length: {maximum: 255}, presence: true
    validates :course_id, presence: true, if: proc {|t| t.topic == 'course' }
    validates :course_id, absence: true, if: proc {|t| t.topic != 'course' }
    validate :allowed_title

    LCHARS = %r{\w+\p{L}\p{N}\-!/#\$%&'*+=?^`{|}~} # rubocop:disable Style/RedundantRegexpEscape
    LOCAL = /[#{LCHARS.source}]+(\.[#{LCHARS.source}]+)*/
    DCHARS = /A-z\d/
    DOMAIN = /[#{DCHARS.source}][#{DCHARS.source}-]*(\.[#{DCHARS.source}-]+)*/
    EMAIL = /\A#{LOCAL.source}@#{DOMAIN.source}\z/i
    validates :mail, presence: true, format: {with: EMAIL}

    belongs_to :course, class_name: '::Course::Course', optional: true

    scope :created_last_day, -> { where(created_at: 1.day.ago..) }
    scope :created_last_year, -> { where(created_at: 1.year.ago..) }

    after_commit(on: :create) do
      Helpdesk::TicketMailer.new_ticket_email(self).deliver_later
      Msgr.publish(as_json, to: 'xikolo.helpdesk.ticket.create')
    end

    STRING_MAX_LENGTH = 255
    before_validation do
      if url && url.length > STRING_MAX_LENGTH
        self.url = url[0...STRING_MAX_LENGTH]
      end
    end

    private

    def allowed_title
      if title&.slice(URI::DEFAULT_PARSER.make_regexp(%w[http https])).present?
        errors.add :title, :invalid
      end
    end
  end
end
