# frozen_string_literal: true

# Updates the text search vector for a question using
# all the questions content including answers and comments.
#
class UpdateQuestionSearchTextWorker
  include Sidekiq::Job

  def perform(id)
    Question.find(id).update_text_search_index
  end
end
