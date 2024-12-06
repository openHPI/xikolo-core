# frozen_string_literal: true

module Xikolo::Course
  class Section < Acfs::Resource
    service Xikolo::Course::Client, path: 'sections'

    attribute :id, :uuid
    attribute :course_id, :uuid
    attribute :course_archived, :boolean
    attribute :title, :string
    attribute :description, :string
    attribute :published, :boolean
    attribute :start_date, :date_time
    attribute :end_date, :date_time
    attribute :optional_section, :boolean, default: false
    attribute :position, :integer
    attribute :effective_start_date, :date_time
    attribute :effective_end_date, :date_time
    attribute :pinboard_closed, :boolean, default: false
    attribute :alternative_state, :string
    attribute :parent_id, :uuid
    attribute :required_section_ids, :list

    def items(user_id = nil, &)
      @items ||= Xikolo::Course::Item.where section_id: id, state_for: user_id
      Acfs.add_callback(@items, &)
      @items
    end

    def published_items(&)
      @published_items ||= Xikolo::Course::Item.where section_id: id, published: true
      Acfs.add_callback(@published_items, &)
      @published_items
    end

    def published?
      published
    end

    def pinboard_closed?
      pinboard_closed
    end

    def available?
      unlocked? && published?
    end

    def was_available?
      was_unlocked? && published?
    end

    def unlocked?
      if course_archived
        (effective_start_date.nil? || effective_start_date <= Time.zone.now) &&
          (end_date.nil? || end_date >= Time.zone.now)
      else
        (effective_start_date.nil? || effective_start_date <= Time.zone.now) &&
          (effective_end_date.nil? || effective_end_date >= Time.zone.now)
      end
    end

    def was_unlocked?
      effective_start_date.nil? || effective_start_date <= Time.zone.now
    end

    def enqueue_tag(&)
      @tag = Xikolo::Pinboard::Tag.find_by(name: id, course_id:, &)
    end

    def enqueue_implicit_tags(&)
      @tag = Xikolo::Pinboard::ImplicitTag.find_by({
        name: id,
        course_id:,
        referenced_resource: 'Xikolo::Course::Section',
      }, &)
    end

    attr_reader :tag

    def alternatives?
      alternative_state == 'parent'
    end

    def alternative?
      alternative_state == 'child'
    end

    def alternatives(&)
      if alternatives?
        @alternatives ||= Xikolo::Course::Section.where parent_id: id
        Acfs.add_callback(@alternatives, &)
      end
      @alternatives
    end

    def enqueue_section_choices(user_id, &)
      if alternatives?
        @choices =
          Xikolo::Course::SectionChoice.where(section_id: id, user_id:)
        Acfs.add_callback(@choices, &)
      end
      @choices
    end

    def section_choice?(id)
      !@choices.nil? && @choices.first.choice_ids.include?(id)
    end

    def section_choices?
      @choices.present? && @alternatives
    end

    def section_choices
      if @choices && @alternatives
        @section_choices ||= @alternatives.select do |a|
          @choices.first.choice_ids.include?(a.id)
        end
      end
      @section_choices
    end
  end
end
