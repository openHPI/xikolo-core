# frozen_string_literal: true

class VideoItemTopicPresenter
  require 'html_truncator'
  include Rails.application.routes.url_helpers
  include MarkdownHelper

  def initialize(topic, course_code)
    @topic = topic
    @course_code = course_code
  end

  def id
    @topic['id']
  end

  def title
    @topic['title']
  end

  def abstract
    truncator.truncate render_markdown(@topic['abstract']) if @topic['abstract'].present?
  end

  def formatted_timestamp
    return '' unless timestamp?

    Time.at(timestamp).utc.strftime('%M:%S')
  end

  def timestamp
    @topic.dig('meta', 'video_timestamp')
  end

  def timestamp?
    timestamp.present?
  end

  def created_at
    @topic['created_at']
  end

  def reply_count
    @topic['num_replies']
  end

  def tags
    @topic['tags']
  end

  def url
    course_question_path(course_id: @course_code, id:)
  end

  private

  def <=>(other)
    [timestamp.to_i, created_at] <=> [other.timestamp.to_i, other.created_at]
  end

  def truncator
    @truncator ||= HtmlTruncator.new
  end
end
