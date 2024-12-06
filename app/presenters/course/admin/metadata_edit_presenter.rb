# frozen_string_literal: true

class Course::Admin::MetadataEditPresenter
  class << self
    def for_course(id:)
      course = Course::Course.by_identifier(id).take!

      new(course)
    end
  end

  def initialize(course)
    @course = course
    @metadata = course.metadata.new
    @errors = ActiveModel::Errors.new nil
  end

  attr_reader :errors

  def to_model
    @metadata
  end

  def course_id
    @course.id
  end

  def course_code
    @course.course_code
  end

  def skills
    @skills ||= @course.skills
  end

  def educational_alignment
    @educational_alignment ||= @course.educational_alignment
  end

  def license
    @license ||= @course.license
  end
end
