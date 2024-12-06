# frozen_string_literal: true

class Xikolo::Quiz::Quiz < Acfs::Resource
  service Xikolo::Quiz::Client, path: 'quizzes'

  attribute :id, :uuid
  attribute :instructions, :string
  attribute :time_limit_seconds, :integer
  attribute :unlimited_time, :boolean, default: false
  attribute :allowed_attempts, :integer
  attribute :unlimited_attempts, :boolean, default: false
  attribute :max_points, :float
  attribute :current_allowed_attempts, :integer
  attribute :current_unlimited_attempts, :boolean
  attribute :current_time_limit_seconds, :integer
  attribute :current_unlimited_time, :boolean
  attribute :external_ref_id, :string

  def enqueue_acfs_request_for_questions(params = {}, &)
    @questions = Xikolo::Quiz::Question.where(params.merge(quiz_id: id, per_page: 250), &)
  end

  attr_reader :questions
end
