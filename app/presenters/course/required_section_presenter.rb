# frozen_string_literal: true

module Course
  class RequiredSectionPresenter < SectionPresenter
    # Gathers the required sections for a section in the context of a user
    #
    # @param section [Course::Section] the section with requirements
    # @param user [Account::User] the user to determine requirements fulfillment for
    # @return [Array<Course::Section>] a list of required sections, or nil if all requirements are fulfilled
    def self.requirements_for(section, user)
      return if section.required_section_ids.blank?

      required_sections = ::Course::Section.where(id: section.required_section_ids).map do |req_section|
        new(req_section, user)
      end

      required_sections.reject(&:fulfilled?)
    end

    def initialize(section, user)
      super(section:)
      @section = section
      @user = user
    end

    def fulfilled?
      @fulfilled ||= @section.fulfilled_for?(@user)
    end

    def id
      @section.id
    end

    def title
      @section.title
    end

    def course_code
      @course_code ||= @section.course.course_code
    end
  end
end
