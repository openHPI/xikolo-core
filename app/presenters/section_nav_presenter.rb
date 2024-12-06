# frozen_string_literal: true

class SectionNavPresenter
  def initialize(user:, view_context:, course:, section: nil, item: nil)
    @user = user
    @view_context = view_context
    @course = course
    @section = section
    @item = item

    load_sections!
  end

  def table_of_contents
    return if @course_sections.nil?

    @table_of_contents ||= Navigation::TableOfContents.for_course(
      context: @view_context,
      user: @user,
      course: @course,
      sections: @course_sections,
      current_section: @section,
      current_item: @item
    )
  end

  private

  def load_sections!
    @course.sections do |sections|
      @course_sections = sections
      @course_sections.each do |section|
        load_items_if_active section
        next unless section.alternatives?

        Acfs.on section.enqueue_section_choices(@user.id), section.alternatives do |_, alternatives|
          section.section_choices if section.section_choices?
          alternatives.each do |alternative|
            load_items_if_active alternative
          end
        end
      end
    end
  end

  def load_items_if_active(section)
    if @user.allowed?('course.content.access')
      return unless section.published?
    else
      return unless section.available?
    end

    # Ensure that we have an Acfs delegator / resource
    return unless @section.respond_to? :loaded?

    # active? requires the loaded (current) section, so let's wait for it.
    Acfs.on @section do |_|
      section.items if active_section?(section)
    end
  end

  def active_section?(section)
    !@section.nil? && (@section.id == section.id)
  end
end
