# frozen_string_literal: true

module Collabspace
  class CalendarEventForm < XUI::Form
    self.form_name = 'calendar_event'

    attribute :id, :uuid
    attribute :user_id, :uuid
    attribute :collab_space_id, :uuid
    attribute :title, :single_line_string
    attribute :description, :text
    attribute :start_time, :datetime
    attribute :end_time, :datetime
    attribute :category, :single_line_string, default: -> { 'other' }
    attribute :all_day, :boolean, default: false

    validates :title, :user_id, :start_time, :end_time, :category, presence: true

    delegate :categories, to: :class

    class << self
      def categories
        [
          [I18n.t('learning_rooms.calendar.categories.available'), 'available'],
          [I18n.t('learning_rooms.calendar.categories.unavailable'), 'unavailable'],
          [I18n.t('learning_rooms.calendar.categories.meeting'), 'meeting'],
          [I18n.t('learning_rooms.calendar.categories.milestone'), 'milestone'],
          [I18n.t('learning_rooms.calendar.categories.other'), 'other'],
        ]
      end
    end

    def can_update?(user)
      user.id == user_id || user.allowed?('collabspace.space.manage')
    end
  end
end
