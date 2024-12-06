# frozen_string_literal: true

class Admin::Classifier::CoursesOrderPresenter
  extend Forwardable

  def_delegators :@classifier, :title, :courses, :cluster

  def initialize(classifier)
    @classifier = classifier
  end

  def courses_order_select
    @classifier.courses.map {|course| ["#{course.title} (#{course.course_code})", course.id] }
  end
end
