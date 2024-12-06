# frozen_string_literal: true

class Xikolo::Pinboard::Subscription < Acfs::Resource
  service Xikolo::Pinboard::Client, path: 'subscriptions'

  attribute :id, :uuid
  attribute :user_id, :uuid
  attribute :question_id, :uuid

  def enqueue_question(&)
    @question = Xikolo::Pinboard::Question.find(question_id, &)
  end

  attr_reader :question
end
