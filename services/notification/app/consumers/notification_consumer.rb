# frozen_string_literal: true

class NotificationConsumer < Msgr::Consumer
  def notify
    unless receiver.notify?(key)
      log_mail! 'disabled'
      return
    end

    result = NotificationMailer.notification(
      receiver,
      key,
      notify_payload.merge(receiver.disable_links(key))
    ).deliver_now

    log_mail! result ? 'success' : 'error'
  rescue Restify::NotFound
    # Ignore errors for non-existing users
  end

  def announcement
    unless receiver.notify?(key)
      log_mail! 'disabled'
      return
    end

    result = NotificationMailer.notification(
      receiver,
      key,
      notify_payload
        .merge(text: text_translations)
        .merge(receiver.disable_links(key))
    ).deliver_now

    log_mail! result ? 'success' : 'error'
  rescue Restify::NotFound
    # Ignore errors for non-existing users
  end

  private

  def log_mail!(state)
    return if notify_payload.fetch('test', true)

    MailLog.find_or_create_by(
      user_id: receiver.id,
      news_id: notify_payload['news_id']
    ).update(
      key:,
      state:,
      course_id: notify_payload['course_id']
    )
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def receiver
    @receiver ||= Resources::Receiver.load_by_id(receiver_id)
  end

  def notify_payload
    payload[:payload]
  end

  def key
    payload.fetch :key
  end

  def receiver_id
    payload.fetch :receiver_id
  end

  def text_translations
    @text_translations ||= news['translations']
      .transform_values {|hash| hash['text'] }
      .merge(
        news['language'] => news['text']
      )
  end

  def news
    @news ||= Xikolo.api(:news).value!.rel(:news).get({
      id: notify_payload.fetch('news_id'),
      embed: 'translations',
    }).value!
  end
end
