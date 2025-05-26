# frozen_string_literal: true

class SectionPresenter < PrivatePresenter
  def_restify_delegators :@section, :id, :title, :published, :alternative_state,
    :description, :required_section_ids, :course_id, :course_archived

  def items
    Xikolo.api(:course).value!.rel(:items).get({section_id: id}).value!.map do |item_resource|
      ItemPresenter.new(item: item_resource, user: @user)
    end
  end

  def to_param
    UUID(id).to_param
  end

  def available?
    unlocked? && published
  end

  def end_date
    Time.zone.parse(@section['end_date'].to_s) if @section['end_date'].present?
  end

  def start_date
    Time.zone.parse(@section['start_date'].to_s) if @section['start_date'].present?
  end

  def effective_start_date
    Time.zone.parse(@section['effective_start_date'].to_s) if @section['effective_start_date'].present?
  end

  def effective_end_date
    Time.zone.parse(@section['effective_end_date'].to_s) if @section['effective_end_date'].present?
  end

  def unlocked?
    start_time = effective_start_date
    end_time = end_date
    end_time = effective_end_date unless course_archived

    (start_time.nil? || start_time <= Time.zone.now) && (end_time.nil? || end_time >= Time.zone.now)
  end

  def alternatives?
    alternative_state == 'parent'
  end

  def fetch_section_choices
    if alternatives?
      @choices ||= Xikolo.api(:course).value!.rel(:section_choices).get({section_id: id}).value!
    end
  end

  def alternatives
    return unless alternatives?

    @alternatives ||= Course::Section.where(parent_id: id)
  end

  def section_choices?
    fetch_section_choices
    alternatives
    @choices.present? && @alternatives
  end

  def section_choice?(id)
    !@choices.nil? && @choices.first['choice_ids'].include?(id)
  end

  def section_choices
    if @choices && @alternatives
      @section_choices ||= @alternatives.select do |a|
        @choices.first['choice_ids'].include?(a['id'])
      end
    end
    @section_choices
  end

  def enqueue_implicit_tags(&)
    @tag = Xikolo::Pinboard::ImplicitTag.find_by({
      name: id,
      course_id:,
      referenced_resource: 'Xikolo::Course::Section',
    }, &)
  end

  def required_sections
    @required_sections ||= ::Course::RequiredSectionPresenter.requirements_for(@section, @user)
  end
end
