# frozen_string_literal: true

class NewsDecorator < ApplicationDecorator
  delegate_all

  # Read tracking was introduced on this date
  MARK_AS_READ_BEFORE = Date.new(2016, 5, 24).freeze

  def basic
    {
      id:,
      title: requested_translation.title,
      author_id:,
      course_id:,
      publish_at:,
      visual_url:,
      show_on_homepage:,
      audience:,
      available_languages:,
      language: requested_translation.locale,
      receivers: receivers.to_i,
      state:,
      sending_state:,
      text: requested_translation.text,
      teaser: requested_translation.teaser,
    }
  end

  def as_json(opts)
    basic.merge(
      url: h.news_path(object),
      email_url: h.announcement_email_path(object),
      user_visit_url: h.announcement_user_visit_rfc6570
        .partial_expand(announcement_id: object.id)
    ).tap do |attrs|
      if embed.include? 'translations'
        attrs[:translations] = other_translations.each_with_object({}) do |t, h|
          h[t.locale] = {title: t.title, text: t.text}
        end
      end

      if context[:read_state]
        attrs[:read] = object.read || publish_at < MARK_AS_READ_BEFORE
      end

      if context[:global_read_count]
        attrs[:read_count] = global_count.first['global_count'] || 0
      end
    end.as_json(opts)
  end

  def as_event(*)
    {
      id:,
      author_id:,
      title: translated_titles,
      course_id:,
      timestamp: Time.now.in_time_zone,
    }.tap do |payload|
      payload[:group] = audience if audience
    end
  end

  private

  def global_count
    read_states.select('count(distinct user_id) as global_count').to_a
  end

  def embed
    @embed ||= context[:embed].to_s.split(',')
  end

  def requested_translation
    @requested_translation ||= translations.find {|t| t.locale == context[:language] } ||
                               translations.find {|t| t.locale == Xikolo.config.locales['default'] } ||
                               translations.find {|t| t.locale == 'en' } ||
                               translations[0]
  end

  def other_translations
    @other_translations ||= translations
      .reject {|t| t.id == requested_translation.id }
  end
end
