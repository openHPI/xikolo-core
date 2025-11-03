# frozen_string_literal: true

# This worker deletes users that have not access the platform since a
# specific cutoff date. Can be used to removed old user accounts before
# a backup or migration for GDPR reasons.

module AccountService
class UserExpiryWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  sidekiq_options retry: false

  def perform(threshold)
    begin
      @threshold = Date.parse(threshold)
    rescue Date::Error => e
      # If the date is invalid, we will stop doing anything.
      Sentry.capture_exception(e)
      Mnemosyne.attach_error(e)
      return
    end

    users_scope.in_batches do |users|
      UserDestroyWorker.perform_bulk(
        users.pluck(:id).map {|id| [id, @threshold.to_s] }
      )
    end
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
