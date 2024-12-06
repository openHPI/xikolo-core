# frozen_string_literal: true

class Xikolo::Quiz::Question < Acfs::Resource
  service Xikolo::Quiz::Client, path: 'questions'

  attribute :id, :uuid
  attribute :quiz_id, :uuid
  attribute :text, :string
  attribute :points, :float
  attribute :explanation, :string
  attribute :shuffle_answers, :boolean, default: true
  attribute :type, :string
  attribute :position, :integer
  attribute :exclude_from_recap, :boolean, default: false

  attr_reader :answers

  def enqueue_acfs_request_for_answers(params = {})
    @answers = []
    Xikolo::Quiz::Answer.each_page params.merge(question_id: id, per_page: 250) do |answers|
      @answers += answers
      yield answers if block_given?
    end
  end
end
