# frozen_string_literal: true

require 'uuid4'

class Xikolo::Pinboard::Question < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'questions'

  attribute :id, :uuid
  attribute :title, :string
  attribute :text, :string
  attribute :video_timestamp, :string
  attribute :video_id, :uuid
  attribute :user_id, :uuid
  attribute :accepted_answer_id, :uuid
  attribute :course_id, :uuid
  attribute :learning_room_id, :uuid
  attribute :discussion_flag, :boolean
  attribute :created_at, :string
  attribute :updated_at, :string
  attribute :votes, :integer
  attribute :answer_count, :integer
  attribute :user_tags, :list
  attribute :implicit_tags, :list
  attribute :comment_count, :integer
  attribute :vote_value_for_requested_user, :integer
  attribute :read, :boolean
  attribute :views, :integer
  attribute :answer_comment_count, :integer
  attribute :attachment_url, :string
  attribute :sticky, :boolean
  attribute :deleted, :boolean, default: false
  attribute :closed, :boolean
  attribute :abuse_report_state, :string
  attribute :abuse_report_count, :integer

  attr_reader :comments, :answers, :tags, :explicit_tags, :section, :item, :author, :file

  def enqueue_answers(params = {})
    @answers = []
    Xikolo::Pinboard::Answer.each_item params.merge(question_id: id, per_page: 250) do |answer|
      @answers << answer
      yield answer if block_given?
    end
  end

  def enqueue_comments(params = {})
    @comments = []
    Xikolo::Pinboard::Comment.each_item(
      params.merge(commentable_id: id, commentable_type: 'Question', per_page: 250)
    ) do |comment|
      @comments << comment
      yield comment if block_given?
    end
  end

  def enqueue_tags(&)
    @tags = Xikolo::Pinboard::Tag.where(question_id: id, &)
  end

  def enqueue_explicit_tags(&)
    @explicit_tags = Xikolo::Pinboard::ExplicitTag.where(question_id: id, &)
  end

  def enqueue_section(&block)
    section_tags = implicit_tags
      .select do |tag|
      tag[:referenced_resource] ==
        'Xikolo::Course::Section'
    end
    section_tags = implicit_tags if section_tags.empty?
    section_tags.each do |section_tag|
      next unless (section_id = UUID4.try_convert(section_tag[:name]))

      Xikolo::Course::Section.find section_id.to_s do |section|
        @section = section
        block&.call @section
      end
    end
  end

  def enqueue_item(&block)
    item_tags = implicit_tags
      .select do |tag|
      tag[:referenced_resource] ==
        'Xikolo::Course::Item'
    end
    item_tags = implicit_tags if item_tags.nil?
    item_tags.each do |item_tag|
      Xikolo::Course::Item.find_by id: item_tag[:name] do |item|
        if item.present?
          @item = item
          block&.call @item
        end
      end
    end
  end

  def enqueue_author(&)
    @author = Xikolo::Account::User.find(user_id, &)
  end

  def technical?
    implicit_tags.any? {|tag| tag['name'] == 'Technical Issues' }
  end

  def report(user_id)
    Xikolo::Pinboard::AbuseReport.create reportable_id: id,
      reportable_type: 'Question',
      user_id:
  end

  def block
    update_attributes({workflow_state: 'blocked'})
  end

  def unblock
    update_attributes({workflow_state: 'reviewed'})
  end

  def blocked?
    %w[blocked auto_blocked].include? abuse_report_state
  end

  def reviewed?
    abuse_report_state == 'reviewed'
  end
end
