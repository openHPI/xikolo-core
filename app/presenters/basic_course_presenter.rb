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

  def tor_enabled?
    Xikolo.config.certificate['transcript_of_records'].present?
  end

  def tor_available?
    tor_enabled? && tor_template?
  end

  def roa_threshold_percentage
    @course['roa_threshold_percentage']
  end

  def cop_threshold_percentage
    @course['cop_threshold_percentage']
  end

  def proctored?
    @course['proctored']
  end

  def certificates_enabled?
    roa_enabled? || cop_enabled? || tor_available?
  end

  def open_badge_enabled?
    certificates_enabled? && open_badge_template?
  end

  def certificates_published?
    certificates_enabled? && @course['records_released']
  end

  def certificate_requirements
    return Array.wrap(I18n.t(:'course.courses.show.tor_requirements')) if tor_available?

    cr = []

    # The guideline link might not exist for all platforms
    if proctored?
      cr << [
        I18n.t(:'course.courses.show.qc_requirements'),
        I18n.t(:'course.courses.show.qc_guidelines_link'),
      ].compact_blank.join(' ')
    end

    cr << I18n.t(:'course.courses.show.roa_requirements', roa_threshold: roa_threshold_percentage) if roa_enabled?
    cr << I18n.t(:'course.courses.show.cop_requirements', cop_threshold: cop_threshold_percentage) if cop_enabled?
    cr << I18n.t(:'course.courses.show.open_badge_requirements') if open_badge_enabled?
    cr
  end

  private

  def tor_template?
    Certificate::Template.exists?(course_id: @course['id'], certificate_type: Certificate::Record::TOR)
  end

  def open_badge_template?
    Certificate::OpenBadgeTemplate.exists?(course_id: @course['id'])
  end
end
