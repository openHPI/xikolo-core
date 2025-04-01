# frozen_string_literal: true

module Course
  ##
  # Used in the course area to present upcoming deadlines, in this course,
  # for the current user.
  #
  class DeadlinesPresenter
    def initialize(user, course)
      @user = user

      return if @user.anonymous?

      course_api = Xikolo.api(:course).value
      return unless course_api&.rel?(:next_dates)

      @promise = course_api.rel(:next_dates).get({
        course_id: course.id,
        user_id: @user.id,
        all: true,
        type: 'item_submission_deadline,on_demand_expires',
      })
    end

    def show?
      @user.logged_in?
    end

    def any?
      deadlines.present?
    end

    def count
      deadlines.count
    end

    def state
      deadlines.any?(&:urgent?) ? 'urgent' : 'uncritical'
    end

    def each
      deadlines.each { yield _1 }
    end

    private

    def deadlines
      @deadlines ||= if @promise&.value
                       @promise.value.map { Deadline.new _1 }
                     else
                       []
                     end
    end

    ##
    # Expects a Restify resource, as fetched from the "Next Dates" endpoint
    # in the course service.
    #
    class Deadline
      def initialize(deadline)
        @deadline = deadline
      end

      # Can this deadline be considered urgent?
      # (In this case, the list will be highlighted to be more visible.)
      def urgent?
        time < 1.day.from_now
      end

      def title
        @deadline['title']
      end

      include ActionView::Helpers::DateHelper

      def due
        I18n.t(
          "next_dates.deadline_widget.events.#{@deadline['type']}",
          when: distance_of_time_in_words(Time.zone.now, @deadline['date'])
        )
      end

      def time
        DateTime.parse(@deadline['date'])
      end

      include Rails.application.routes.url_helpers

      def url
        case @deadline['type']
          when 'on_demand_expires'
            course_resume_path(@deadline['course_code'])
          when 'item_submission_deadline'
            course_item_path(@deadline['course_code'], short_resource_uuid)
        end
      end

      private

      def short_resource_uuid
        UUID(@deadline['resource_id']).to_param
      end
    end
  end
end
