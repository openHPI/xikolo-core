# frozen_string_literal: true

module CourseService
class Enrollment::Update < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  attr_reader :params, :enrollment

  def initialize(enrollment_id, params)
    super()
    @enrollment_id = enrollment_id
    @params = params
  end

  def call
    Enrollment.transaction do
      @enrollment = Enrollment.with_evaluation.find(@enrollment_id)
      process_completed! if params.key? :completed
      enrollment.assign_attributes params
      enrollment.save!
    end
    enrollment
  rescue ActiveRecord::RecordInvalid => e
    e.record
  end

  private

  def process_completed!
    wanted_value = params.delete :completed
    # set completed temporary to nil, to get current default value
    enrollment.completed = nil
    return if enrollment.completed? == wanted_value

    enrollment.completed = wanted_value
  end
end
end
