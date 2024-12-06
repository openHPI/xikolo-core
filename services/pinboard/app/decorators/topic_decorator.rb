# frozen_string_literal: true

class TopicDecorator < Draper::Decorator
  delegate_all

  def as_json(opts)
    {
      **fields(opts),
      **urls,
    }.as_json(opts)
  end

  private

  def fields(opts)
    {
      id:,
      title:,
      abstract:,
      tags:,
      closed: closed?,
      num_replies:,
      meta:,
      created_at:,
    }.tap do |fields|
      if opts[:embed]&.include? 'posts'
        fields[:posts] = PostDecorator.decorate_collection posts
      end
    end
  end

  def urls
    {
      url: h.topic_path(id),
    }
  end

  def tags
    object.explicit_tags.map do |tag|
      {
        id: tag.id,
        name: tag.name,
      }
    end
  end

  def abstract
    object.text.truncate(150, separator: /\s/)
  end

  def meta
    return {} if object.video_timestamp.blank?

    {
      'video_timestamp' => object.video_timestamp,
    }
  end

  def posts
    [
      object,
      *object.comments,
      *object.answers,
      *object.answers.flat_map(&:comments),
    ]
      .sort_by(&:created_at)
      .map {|p| Post.new p }
  end
end
