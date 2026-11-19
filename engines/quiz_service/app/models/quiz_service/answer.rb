# frozen_string_literal: true

module QuizService
class Answer < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = 'quiz_answers'

  delegate :url_helpers, to: 'Rails.application.routes'

  default_scope { order(:position) }
  belongs_to :question
  acts_as_list scope: :question
  has_paper_trail

  after_commit(on: :destroy) do
    Xikolo::S3.extract_file_refs(text).each do |uri|
      Xikolo::S3.object(uri).delete
    end
  end
end
end
