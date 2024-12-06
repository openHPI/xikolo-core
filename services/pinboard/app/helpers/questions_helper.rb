# frozen_string_literal: true

module QuestionsHelper
  def watch_count
    Watch.where(question_id: id).count
  end
end
