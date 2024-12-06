# frozen_string_literal: true

class SectionProgress::Calculate < ApplicationOperation
  def initialize(section_id, user_id, stale_at: nil, update_course_progress: true)
    super()

    @section_id = section_id
    @user_id = user_id
    @stale_at = stale_at
    @update_course_progress = update_course_progress
  end

  def call
    return section_progress if already_updated?

    section_progress.calculate!
    if @update_course_progress
      LearningEvaluation::UpdateCourseProgressWorker
        .perform_async(section_progress.section.course_id, @user_id)
    end

    section_progress
  end

  private

  def section_progress
    @section_progress ||= SectionProgress.find_or_create_by!(
      user_id: @user_id,
      section_id: @section_id
    )
  rescue ActiveRecord::RecordNotUnique
    # Retry on race condition in between find and create.
    retry
  end

  def already_updated?
    return false unless @stale_at
    # Do not skip the calculation if the section progress was just created.
    return false if section_progress.previous_changes.key?('created_at')

    @stale_at < section_progress.updated_at
  end
end
