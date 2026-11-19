# frozen_string_literal: true

class BasicCoursePresenter
  def initialize(course)
    @course = course
  end

  def id
    @course['id']
  end

  def title
    @course['title']
  end

  def course_code
    @course['course_code']
  end

  def stage_visual_url
    @course['stage_visual_url']
  end

  def visual_url
    @course['visual_url']
  end

  def roa_enabled?
    @course['roa_enabled']
  end

  def cop_enabled?
    @course['cop_enabled']
  end

  def course_format
    @course['course_format']
  end

  def roa_threshold_percentage
    @course['roa_threshold_percentage']
  end

  def cop_threshold_percentage
    @course['cop_threshold_percentage']
  end

  def certificates_enabled?
    roa_enabled? || cop_enabled?
  end

  def certificates_published?
    certificates_enabled? && @course['records_released']
  end

  def certificate_requirements
    cr = []
    exam = @course.exam

    cr << I18n.t(:'course.courses.show.cop_requirements', cop_threshold: cop_threshold_percentage) if cop_enabled?
    if roa_enabled? && exam.present?
      roa_with_exam = I18n.t(
        :'course.courses.show.roa_requirements_with_exam',
        exam_threshold: exam.minimum_progress_percentage,
        pass_percentage: exam.content.pass_percentage
      )
      cr << roa_with_exam
    elsif roa_enabled?
      cr << I18n.t(:'course.courses.show.roa_requirements', roa_threshold: roa_threshold_percentage)
    end
    cr
  end
end
