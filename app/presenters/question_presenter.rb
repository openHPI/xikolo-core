# frozen_string_literal: true

class QuestionPresenter < Presenter
  extend Forwardable
  include Rails.application.routes.url_helpers

  attr_accessor :question, :course, :section_id

  def_delegators :question,
    :closed,
    :discussion_flag,
    :id,
    :last_activity,
    :sticky,
    :text,
    :title,
    :updated_at,
    :votes

  def self.build(question, course, section_id)
    question.enqueue_comments unless question.comment_count
    unless question.answer_count && question.answer_comment_count
      question.enqueue_answers(&:enqueue_comments)
    end

    question.enqueue_explicit_tags unless question.user_tags
    question.enqueue_section
    question.enqueue_item
    p = new(question:, course:, section_id:)
    p.author_name!
    p
  end

  def reply_count
    answer_count + comment_count + answer_comment_count
  end

  def answer_count
    question.answer_count || question.answers.size
  end

  def comment_count
    question.comment_count || question.comments.size
  end

  # number of comments for answers of this question
  def answer_comment_count
    question.answer_comment_count || question.answers.map(&:comments).flatten!.size
  end

  def response_count
    # Implemented for XI-847. This is supposed to show the general feedback for
    # a question. Once the users understood the difference between answers and
    # comments, this should be reverted.
    #
    # TODO: Oh really? See XI-853. :P
    answer_count + comment_count + answer_comment_count
  end

  def read?
    if question.read.nil?
      false
    else
      question.read
    end
  end

  def view_count
    question.views || 0
  end

  def to_param
    id
  end

  def accepted_answer?
    !question.accepted_answer_id.nil?
  end

  def user_tags
    question.user_tags || question.explicit_tags.map(&:name)
  end

  def question_scopes
    [question.section, question.item].compact.map(&:title)
  end

  def author_name
    @author_name || question.author.name
  end

  # ensure author name is loaded
  def author_name!
    cache_key = "users/#{question.user_id}/name"
    if Rails.cache.exist? cache_key
      @author_name = Rails.cache.read cache_key
    else
      question.enqueue_author do |user|
        Rails.cache.write cache_key, user.name
        @author_name = user.name
      end
    end
  end

  def course_section_path
    course_section_question_path course_id: course.course_code,
      section_id: @section_id,
      id: question.id
  end

  def image_thumbnail_url; end

  def title
    t = question.title
    t = "#{I18n.t(:'pinboard.reporting.blocked')} #{t}" if question.blocked?
    t
  end
end
