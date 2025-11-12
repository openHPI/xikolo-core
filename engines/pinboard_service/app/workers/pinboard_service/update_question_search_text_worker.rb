# frozen_string_literal: true

# Updates the text search vector for a question using
# all the questions content including answers and comments.

module PinboardService
class UpdateQuestionSearchTextWorker #  rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(id)
    if id.present?
      Question.find(id).update_text_search_index
    end
  end
end
end
