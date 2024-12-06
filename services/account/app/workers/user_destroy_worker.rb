# frozen_string_literal: true

# Asynchronously destroys a user and associated account resources. The
# actual deletion is handled by the User::Destroy operation, but that
# can fail due to external calls, and the worker can retry that.
#
# An optional date threshold can be given to skip deletion if the user
# accessed their account afterwards.
#
class UserDestroyWorker
  include Sidekiq::Job

  def perform(user, threshold = nil)
    begin
      threshold &&= Date.parse(threshold)
    rescue Date::Error => e
      # If the date is invalid, we will stop doing anything.
      Sentry.capture_exception(e)
      Mnemosyne.attach_error(e)
      return
    end

    begin
      record = User.resolve(user)
    rescue ActiveRecord::RecordNotFound => e
      # This shouldn't even happen since we only soft-delete user
      # records (archived: true), but if the record really does not
      # exist, we truly do not need to continue.
      Sentry.capture_exception(e)
      Mnemosyne.attach_error(e)
      return
    end

    if threshold && !record.last_access&.before?(threshold)
      # User has accessed their account after the threshold date, so we
      # skip destroying.
      return
    end

    User::Destroy.call(record)
  end
end
