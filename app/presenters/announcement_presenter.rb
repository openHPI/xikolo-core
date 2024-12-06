# frozen_string_literal: true

class AnnouncementPresenter < Presenter
  require 'html_truncator'
  include MarkdownHelper

  attr_accessor :news

  def self.create(news)
    new news:
  end

  def id
    news['id']
  end

  def title
    news['title']
  end

  def text
    news['text']
  end

  def teaser
    truncator.truncate render_markdown(text) unless text.nil?
  end

  def publish_at
    news['publish_at'] && DateTime.parse(news['publish_at'])
  end

  def visual_url
    news['visual_url']
  end

  def visual_url?
    visual_url.present?
  end

  private

  def truncator
    @truncator ||= HtmlTruncator.new
  end
end
