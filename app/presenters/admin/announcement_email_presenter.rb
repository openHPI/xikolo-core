# frozen_string_literal: true

class Admin::AnnouncementEmailPresenter
  def initialize(announcement, email)
    @announcement = announcement
    @email = email

    # Start loading information about users (creator and sender)
    account_api = Xikolo.api(:account).value!
    @author_promise = account_api.rel(:user).get(id: author_id)
    @sender_promise = account_api.rel(:user).get(id: sender_id)
  end

  def authored_at
    I18n.l Time.zone.parse(@announcement['created_at']), format: :short_datetime
  end

  def author_id
    @announcement['author_id']
  end

  def author_name
    @author_promise.value!['full_name']
  end

  def sent_at
    I18n.l Time.zone.parse(@email['created_at']), format: :long_datetime
  end

  def sender_id
    @email['creator_id']
  end

  def sender_name
    @sender_promise.value!['full_name']
  end

  def recipients
    @email['recipients'].join ', '
  end

  def subject
    @email['subject']
  end

  def status
    @email['status']
  end

  def total_deliveries
    @email['deliveries']['total']
  end

  def successful_deliveries
    @email['deliveries']['success']
  end

  def disabled_deliveries
    # The count for disabled notifications needs to be implemented.
    @email['deliveries']['disabled'] || 0
  end

  def error_deliveries
    # The count for erroneous deliveries needs to be implemented.
    @email['deliveries']['error'] || 0
  end

  def deliveries_percentage
    return 0 if total_deliveries.zero?

    ((successful_deliveries + disabled_deliveries + error_deliveries) / total_deliveries.to_f * 100).to_i
  end

  def num_opens
    @email['num_opens'] || 0
  end

  def opens_percentage
    return 0 if successful_deliveries.zero?

    (num_opens / successful_deliveries.to_f * 100).to_i
  end
end
