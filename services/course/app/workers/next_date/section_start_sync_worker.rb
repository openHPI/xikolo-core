# frozen_string_literal: true

# Keep the `section_start` next date in sync with the
# actual section (start)
#
# The worker creates or updates the event if a next date
# should be present for the course. Otherwise an existing
# next date resource is removed.
class NextDate::SectionStartSyncWorker
  include Sidekiq::Job

  def perform(section_id)
    @section_id = section_id

    return purge! unless applicable?

    NextDate
      .find_or_initialize_by(slot_id:)
      .update(attrs)
  end

  private

  def section
    @section ||= Section.published.find_by(id: @section_id)
  end

  def applicable?
    section&.start_date?
  end

  def purge!
    NextDate.where(slot_id:).delete_all
  end

  def attrs
    {
      user_id: NextDate.nil_user_id,
      type: 'section_start',
      resource_type: 'section',
      resource_id: @section_id,
      course_id: @section.course_id,
      date: section.start_date,
      title: section.title,
      section_pos: section.position,
      item_pos: 0,
      visible_after: course_start_date,
    }
  end

  def slot_id
    @slot_id ||= NextDate.calc_id(@section_id, 'section_start')
  end

  def course_start_date
    section.course.display_start_date || section.course.start_date
  end
end
