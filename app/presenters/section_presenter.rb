# frozen_string_literal: true

class SectionPresenter < PrivatePresenter
  def_delegators :@section, :id, :title, :available?, :was_available?,
    :start_date, :end_date, :published?, :pinboard_closed?, :alternatives?,
    :section_choices?, :description, :section_choice?, :required_section_ids

  def items
    @section.items.map do |item|
      ItemPresenter.new item:, user: @user
    end
  end

  def to_param
    UUID(id).to_param
  end

  def alternatives
    return unless @section.alternatives?

    @section.alternatives.map do |alternative|
      SectionPresenter.new section: alternative
    end
  end

  def section_choices
    return unless @section.section_choices?

    @section.section_choices.map do |alternative|
      SectionPresenter.new section: alternative
    end
  end

  def required_sections
    @required_sections ||= ::Course::RequiredSectionPresenter.requirements_for(@section, @user)
  end
end
