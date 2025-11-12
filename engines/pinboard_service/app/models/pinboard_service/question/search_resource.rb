# frozen_string_literal: true

module PinboardService
module Question::SearchResource # rubocop:disable Layout/IndentationWidth
  extend ActiveSupport::Concern

  included do
    after_commit :schedule_search_text_update
  end

  def schedule_search_text_update
    UpdateQuestionSearchTextWorker.perform_async(question_id)
  end
end
end
