# frozen_string_literal: true

# This job deletes users that have not accessed the platform since a
# specific cutoff date. Can be used to remove old user accounts before
# a backup or migration for GDPR reasons.

module AccountService
  class UserExpiryJob < ApplicationJob
    queue_as :default

    discard_on StandardError

    def perform(threshold)
      begin
        @threshold = Date.parse(threshold)
      rescue Date::Error => e
        # If the date is invalid, we will stop doing anything.
        Sentry.capture_exception(e)
        return
      end

      jobs = users_scope.in_batches.flat_map do |batch|
        batch.map do |user|
          UserDestroyJob.new(user.id, @threshold.to_s)
        end
      end

      ActiveJob.perform_all_later(jobs)
    end

    private

    def users_scope
      User.unscope(:order)
        .where(anonymous: false)
        .where(archived: false)
        .where.not(last_access: nil)
        .where(last_access: ..@threshold)
    end
  end
end
