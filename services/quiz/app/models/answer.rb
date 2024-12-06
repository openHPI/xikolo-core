# frozen_string_literal: true

class Answer < ApplicationRecord
  self.table_name = 'quiz_answers'

  delegate :url_helpers, to: 'Rails.application.routes'

  default_scope { order('position ASC') }
  belongs_to :question
  acts_as_list scope: :question
  has_paper_trail

  after_commit(on: :create) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.answer.create')
  end
  after_commit(on: :update) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.answer.update')
  end
  after_commit(on: :destroy) do
    Msgr.publish(decorate.as_event, to: 'xikolo.quiz.answer.destroy')
  end
  after_commit(on: :destroy) do
    Xikolo::S3.extract_file_refs(text).each do |uri|
      Xikolo::S3.object(uri).delete
    end
  end
end
