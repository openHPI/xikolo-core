# frozen_string_literal: true

# A meta-model representing either a question, answer or comment
#
# Once data is migrated, this will be a real ActiveRecord model, storing all
# data in the posts table. Until then, most operations will have to be
# delegated to the corresponding "real" model.
class Post
  def self.find(id)
    post = Question.find_by(id:)
    post ||= Answer.find_by(id:)
    post ||= Comment.find_by(id:)

    return new(post) if post

    raise ActiveRecord::RecordNotFound.new("Unable to find post #{id}")
  end

  def initialize(wrapped)
    @wrapped = wrapped
  end

  extend Forwardable

  def_delegators :@wrapped,
    :id, :created_at, :text, :blocked?, :votes, :destroy

  def author_id
    @wrapped.user_id
  end

  def downvotes?
    !@wrapped.is_a? Question
  end

  # Update or create a vote value for a given user
  #
  # value can be 0, -1 or 1. There will only be one Vote instance per user and
  # post. That instance will be returned from this method.
  def vote(value, user_id:)
    @wrapped.votes.find_or_create_by(user_id:).tap do |vote|
      vote.update(value:)
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def decorate
    PostDecorator.decorate(self)
  end
end
