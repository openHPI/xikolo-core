# frozen_string_literal: true

module NewsService
class MessageDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(_opts = {})
    fields
  end

  protected

  def fields
    {
      id:,
      subject: localized_subject,
      content: localized_content,
      recipients:,
      status:,
      creator_id:,
      created_at:,
      deliveries:,
      # The number of users who have opened a message needs to be
      # implemented / migrated.
      # num_opens: 0,
    }
  end

  def requested_locale
    @requested_locale ||= model.language_with(context[:language])
  end

  def localized_subject
    model.translations.fetch(requested_locale)['subject']
  end

  def localized_content
    model.translations.fetch(requested_locale)['content']
  end

  def deliveries_count
    @deliveries_count ||= model.deliveries.count
  end

  def deliveries
    {
      total: deliveries_count,
      success: deliveries_count,
      # Errors and disabled notifications need to be implemented / migrated.
      # error: 0,
      # disabled: 0,
    }
  end
end
end
