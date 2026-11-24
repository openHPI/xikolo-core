# frozen_string_literal: true

# All published optional items of a course the learner has access to, of any
# type: the items marked as optional and those in optional sections, which do
# not count towards the course progress. With the learner's progress on them,
# in course order.
class Course::OptionalItemListPresenter
  include Enumerable

  # @param course [CourseService::Course]
  # @param user_id [String]
  # @param progresses [Array<Hash>] section progresses followed by the course
  #   progress, telling which alternative sections the learner takes
  # @param current_item_id [String, nil] the item the learner resumes the course at
  def initialize(course, user_id, progresses, current_item_id: nil)
    @course = course
    @user_id = user_id
    @progresses = progresses
    @current_item_id = current_item_id
  end

  def each(&)
    items.each(&)
  end

  private

  # Optional quizzes show the same progress as in the quiz list, e.g. failed
  # or past their submission deadline.
  def items
    @items ||= optional_items.map do |item|
      current = item.id == @current_item_id

      if item.quiz?
        Course::QuizListPresenter::QuizPresenter.new(item, @course, @user_id, enrollment, current:)
      else
        Course::LearnerItemPresenter.new(item, @course, current:)
      end
    end
  end

  # A reactivated enrollment postpones the quizzes' submission deadlines.
  def enrollment
    return @enrollment if defined?(@enrollment)

    @enrollment = CourseService::Enrollment.find_by(course_id: @course.id, user_id: @user_id)
  end

  def optional_items
    optional = CourseService::Item.optional
      .or(CourseService::Item.where(section_id: CourseService::Section.optional.select(:id)))

    Course::LearnerItems.new(@course, @user_id, @progresses)
      .items(scope: optional)
      .preload(section: :course)
  end
end
