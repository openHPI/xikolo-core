# frozen_string_literal: true

module Xikolo::Pinboard
  class Statistic < Acfs::Resource
    service Xikolo::Pinboard::Client, path: 'statistics'

    attribute :threads, :integer
    attribute :threads_last_day, :integer
    attribute :posts, :integer
    attribute :posts_last_day, :integer

    attribute :questions, :integer
    attribute :questions_last_day, :integer
    attribute :answers, :integer
    attribute :answers_last_day, :integer
    attribute :comments_on_answers, :integer
    attribute :comments_on_answers_last_day, :integer
    attribute :comments_on_questions, :integer
    attribute :comments_on_questions_last_day, :integer
    attribute :user, :dict
  end
end
