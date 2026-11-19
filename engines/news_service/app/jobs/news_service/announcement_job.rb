# frozen_string_literal: true

# The `AnnouncementJob` triggers the message creation
# on the saved publishing time of the announcement. The job shall be
# scheduled on each edit, it will check if the announcement has been changed
# when the job is run. Only the most recent job will invoke
# create the message.
#
# Use `AnnouncementJob::call(announcement)` for proper scheduling using
# `announcement.publish_at` as the intended execution time.
#
module NewsService
  class AnnouncementJob < ApplicationJob
    queue_as :default

    def perform(id, created_at)
      begin
        announcement = Announcement
          .where(updated_at: ..Time.iso8601(created_at))
          .find(id)
      rescue ActiveRecord::RecordNotFound
        # Silently exit if the announcement has been edited after this job
        # has been scheduled.
        return
      end

      Message::Create.call(announcement)
    end

    class << self
      def call(announcement, created_at: Time.now.utc)
        set(wait_until: announcement.publish_at)
          .perform_later(
            announcement.id,
            created_at.iso8601(9)
          )
      end
    end
  end
end
