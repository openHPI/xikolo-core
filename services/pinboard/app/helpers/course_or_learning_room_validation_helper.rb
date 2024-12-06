# frozen_string_literal: true

module CourseOrLearningRoomValidationHelper
  private
  def course_or_learning_room
    if course_id.blank? && learning_room_id.blank?
      errors.add :course_id, 'A question needs a course_id or a learning_room_id!'
    end
  end
end
