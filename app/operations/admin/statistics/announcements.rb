# frozen_string_literal: true

module Admin
  module Statistics
    class Announcements < ApplicationOperation
      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        # Get API endpoints for announcements and email delivery stats
        mail_log_stats = Xikolo.api(:notification).value!.rel(:mail_log_stats)
        news_index = Xikolo.api(:news).value!.rel(:news_index)

        # Fetch announcements: course-specific or global
        news_list = if @course_id
                      Xikolo.api(:course).value!.rel(:course).get({id: @course_id})
                        .then do |course|
                          news_index.get({
                            course_id: course['id'],
                            global_read_count: true,
                            per_page: 10,
                          })
                        end
                    else
                      news_index.get({
                        global: true,
                        global_read_count: true,
                        per_page: 5,
                      })
                    end.value!

        # Combine announcement data with email delivery statistics
        statistics = news_list.map do |news|
          mail_log_stats.get({news_id: news['id']}).then do |stats|
            {
              newest: stats['newest'],
              totalCount: news['receivers'],
              successCount: stats['success_count'],
              errorCount: stats['error_count'],
              disabledCount: stats['disabled_count'],
              globalReadCount: news['read_count'],
              state: news['state'],
              newsTitle: news['title'],
            }
          end
        end.map!(&:value!)

        return [] if statistics.blank?

        # Format data for Global::Table component
        statistics.map do |news|
          {
            news_title: news[:newsTitle],
            counts: "#{news[:totalCount]} / #{news[:successCount]} / #{news[:errorCount]} / " \
                    "#{news[:disabledCount]} / #{news[:globalReadCount]}",
            date_sent: format_date(news[:newest]),
            state: format_state(news[:state]),
          }
        end
      end

      private

      def format_date(iso8601)
        return '' if iso8601.blank?

        time = Time.zone.parse(iso8601)
        time.strftime('%Y-%m-%d %H:%M')
      end

      def format_state(state)
        return '' if state.blank?

        I18n.t("admin.statistics.news.state_text.text_#{state}", default: state)
      end
    end
  end
end
