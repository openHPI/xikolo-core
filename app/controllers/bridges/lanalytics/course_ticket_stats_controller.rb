# frozen_string_literal: true

module Bridges
  module Lanalytics
    class CourseTicketStatsController < BaseController
      respond_to :json

      def show
        stats = Helpdesk::Ticket.where course_id: params[:course_id]

        respond_with({
          ticket_count: stats.count,
          ticket_count_last_day: stats.created_last_day.count,
        })
      end
    end
  end
end
