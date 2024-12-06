# frozen_string_literal: true

module Collabspace
  class CalendarEventPresenter < PrivatePresenter
    COLOR_MAP = {
      'available' => '#88b96a',
      'unavailable' => '#dc7671',
      'meeting' => '#9aabf8',
      'milestone' => '#f7af6a',
      'other' => '#e4b6df',
    }.freeze

    class << self
      def create(event, view)
        new event:, view:
      end
    end

    attr_accessor :event, :view

    def id
      event['id']
    end

    def start_time
      Time.iso8601 event['start_time']
    end

    def end_time
      Time.iso8601 event['end_time']
    end

    def color
      COLOR_MAP[event['category']] || COLOR_MAP['other']
    end

    def as_json(*)
      {
        id:,
        title: event['title'],
        start: start_time.iso8601,
        end: end_time.iso8601,
        color:,
        allDay: event['all_day'],
        update_url: view.course_learning_room_calendar_event_path(
          view.params[:course_id], view.params[:learning_room_id], id
        ),
        edit_url: view.edit_course_learning_room_calendar_event_path(
          view.params[:course_id], view.params[:learning_room_id], id
        ),
      }
    end
  end
end
