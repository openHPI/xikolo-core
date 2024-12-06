# frozen_string_literal: true

module NotificationUserSettingsHelper
  # Build a hash from emailID and userID.
  # See Notification Service for reference.
  def hash_email(id:, user_id:)
    Digest::SHA256.hexdigest [id, user_id].join
  end

  # Translate the key passed in an email back
  # to the original settings key.
  def settings_key(key_substitute)
    sanitized_key = key_substitute.gsub(/[^a-z_]/, '')

    {
      'global' => 'notification.email.global',
      'announcement' => 'notification.email.news.announcement',
      'course_announcement' => 'notification.email.course.announcement',
      'pinboard' => 'notification.email.pinboard.new_answer',
    }.fetch sanitized_key
  end
end
