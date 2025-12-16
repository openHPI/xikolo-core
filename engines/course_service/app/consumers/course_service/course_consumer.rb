# frozen_string_literal: true

module CourseService
class CourseConsumer < Msgr::Consumer # rubocop:disable Layout/IndentationWidth
  def clone
    return unless payload \
      && payload[:old_course_id] \
      && payload[:new_course_code]

    # were the node that will take care, avoid multiple nodes taking care
    message.ack
    # lets do the job
    Course::Clone.call(
      payload[:old_course_id],
      payload[:new_course_code]
    )
  end
end
end
