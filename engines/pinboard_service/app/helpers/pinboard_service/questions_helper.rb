# frozen_string_literal: true

module PinboardService
module QuestionsHelper # rubocop:disable Layout/IndentationWidth
  def watch_count
    Watch.where(question_id: id).count
  end
end
end
