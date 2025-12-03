# frozen_string_literal: true

# The `AnnouncementWorker` triggers the message creation
# on the saved publishing time of the announcement. The worker shall be
# scheduled on each edit, it will check if the announcement has been changed
# when the worker is run. Only the most recent worker will invoke
# create the message.
#
# Use `AnnouncementWorker::call(announcement)` for proper scheduling using
# `announcement.publish_at` as the intended execution time.
#
module NewsService
class AnnouncementWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(id, created_at)
    begin
      announcement = Announcement
        .where(updated_at: ..Time.iso8601(created_at))
        .find(id)
    rescue ActiveRecord::RecordNotFound
      # Silently exit if the announcement has been edited after this worker
      # has been scheduled.
      return
    end

    Message::Create.call(announcement)
  end

  class << self
    def call(announcement, created_at: Time.now.utc)
      perform_at(
        announcement.publish_at,
        announcement.id,
        created_at.iso8601(9)
      )
    end
  end
end
end
