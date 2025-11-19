# frozen_string_literal: true

module Xikolo
  module V2
    class StatisticsAPI < Grape::API::Instance
      helpers do
        def percent(number, total)
          if (t = total.to_i) == 0
            0
          else
            number.to_i * 100 / t
          end
        end

        def global_dashboard_permission!
          permission! 'global.dashboard.show'
        end

        def course_dashboard_permission!(course_id)
          course = course_api.rel(:course).get({id: course_id}).value!
          in_context course['context_id']
          permission! 'course.dashboard.view'
        end

        def dashboard_permission!(course_id)
          if course_id.nil?
            global_dashboard_permission!
          else
            course_dashboard_permission! course_id
          end
        end

        def course_item_stats_permission!(item_id)
          item = course_api.rel(:item).get({id: item_id}).value!
          course = course_api.rel(:course).get({id: item['course_id']}).value!
          in_context course['context_id']
          permission! 'course.item_stats.show'
        end

        def course_item_stats_permission_for_quiz!(quiz_id)
          item = course_api.rel(:items).get({content_id: quiz_id}).value!.first
          course = course_api.rel(:course).get({id: item['course_id']}).value!
          in_context course['context_id']
          permission! 'course.item_stats.show'
        end

        def course_item_stats_permission_for_question!(question_id)
          question = quiz_api.rel(:question).get({id: question_id}).value!
          item = course_api.rel(:items).get({content_id: question['quiz_id']}).value!.first
          course = course_api.rel(:course).get({id: item['course_id']}).value!
          in_context course['context_id']
          permission! 'course.item_stats.show'
        end

        def available_metrics
          @available_metrics ||= begin
            metrics_list = lanalytics_api.rel(:metrics).get.value!
            metrics_list.select {|metric| metric['available'] }.pluck('name')
          end
        end

        def metrics_available?(*names)
          # Checks the availability of the metric's datasource
          # AND whether the metric exists (name) at all
          names.map(&:underscore).all? {|name| available_metrics.include?(name) }
        end

        def fetch_metric(name:, **params)
          return lanalytics_api.rel(:metric).get({**params, name:}) if metrics_available?(name)

          Restify::Promise.fulfilled(nil)
        end

        def checksum(for_hash:)
          # to_query transforms the hash into a string representation and
          # sorts lexicographically in ascending order
          Digest::MD5.hexdigest(for_hash.to_query)
        end

        def account_api
          @account_api ||= Xikolo.api(:account).value!
        end

        def course_api
          @course_api ||= Xikolo.api(:course).value!
        end

        def lanalytics_api
          @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
        end

        def news_api
          @news_api ||= Xikolo.api(:news).value!
        end

        def notification_api
          @notification_api ||= Xikolo.api(:notification).value!
        end

        def pinboard_api
          @pinboard_api ||= Xikolo.api(:pinboard).value!
        end

        def quiz_api
          @quiz_api ||= Xikolo.api(:quiz).value!
        end
      end

      namespace 'statistics' do
        namespace 'course_dashboard' do
          params do
            requires :course_id, type: String, desc: 'The course UUID'
          end

          namespace 'enrollments' do
            desc 'Returns course-specific KPIs related to enrollments'
            get do
              course_dashboard_permission! params[:course_id]

              course = course_api.rel(:course).get({id: params[:course_id]}).value!
              Rails.cache.fetch("statistics/course/#{params[:course_id]}/enrollments/", expires_in: 1.hour, race_condition_ttl: 1.minute) do
                Restify::Promise.new(
                  course_api.rel(:stats).get({course_id: params[:course_id], key: 'enrollments'}),
                  course_api.rel(:stats).get({course_id: params[:course_id], key: 'shows_and_no_shows'}),
                  fetch_metric(name: 'certificates', course_id: params[:course_id]),
                  fetch_metric(name: 'certificates', course_id: params[:course_id], start_date: course['start_date'], end_date: course['end_date']),
                  fetch_metric(name: 'certificates', course_id: params[:course_id], start_date: course['end_date'])
                ) do |enrollment_stats, show_stats, certificates, certificates_at_end, certificates_after_end|
                  {
                    enrollments: enrollment_stats['enrollments'],
                    enrollments_netto: enrollment_stats['enrollments_netto'],
                    enrollments_last_day: enrollment_stats['enrollments_last_day'],
                    enrollments_at_start: enrollment_stats['enrollments_at_start'],
                    enrollments_at_start_netto: enrollment_stats['enrollments_at_start_netto'],
                    enrollments_at_middle: enrollment_stats['enrollments_at_middle'],
                    enrollments_at_middle_netto: enrollment_stats['enrollments_at_middle_netto'],
                    enrollments_at_end: enrollment_stats['enrollments_at_end'],
                    enrollments_at_end_netto: enrollment_stats['enrollments_at_end_netto'],

                    shows: show_stats['shows'],
                    shows_at_middle: show_stats['shows_at_middle'],
                    shows_at_end: show_stats['shows_at_end'],
                    show_quota: percent(show_stats['shows'], enrollment_stats['enrollments']),
                    show_quota_at_middle: percent(show_stats['shows_at_middle'], enrollment_stats['enrollments_at_middle']),
                    show_quota_at_end: percent(show_stats['shows_at_end'], enrollment_stats['enrollments_at_end']),

                    roa_count: certificates['record_of_achievement'],
                    cop_count: certificates['confirmation_of_participation'],
                    qc_count: certificates['qualified_certificate'],
                    cop_at_end_count: certificates_at_end['confirmation_of_participation'],
                    cop_after_end_count: certificates_after_end['confirmation_of_participation'],

                    completion_rate: percent(certificates['record_of_achievement'], show_stats['shows_at_middle']),
                    consumption_rate_at_end: percent(certificates_at_end['confirmation_of_participation'], show_stats['shows_at_end']),
                    consumption_rate_after_end: percent(certificates_after_end['confirmation_of_participation'], show_stats['shows'].to_i - show_stats['shows_at_end'].to_i),
                    consumption_rate_current: percent(certificates['confirmation_of_participation'], show_stats['shows']),
                  }
                end.value!
              end
            end
          end

          namespace 'downloads' do
            desc 'Returns course-specific video asset downloads'
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'download_total_count', course_id: params[:course_id]).value!
            end
          end

          namespace 'rich_text_link_clicks' do
            desc 'Returns course-specific rich text link clicks'
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'rich_text_link_click_total_count', course_id: params[:course_id]).value!
            end
          end

          namespace 'open_badges' do
            get do
              course_dashboard_permission!(params[:course_id])

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/open_badges/", expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                Restify::Promise.new(
                  fetch_metric(name: 'badge_download_count', course_id: params[:course_id]),
                  fetch_metric(name: 'badge_share_count', course_id: params[:course_id])
                ) do |badge_downloads, badge_shares|
                  {
                    badge_issues: Certificate::OpenBadge.issue_count(params[:course_id]).to_i,
                    badge_downloads: badge_downloads['count'].to_i,
                    badge_shares: badge_shares['count'].to_i,
                  }
                end.value!
              end
            end
          end

          namespace 'bookings' do
            desc 'Returns course-specific booking KPIs'
            get do
              course_dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/bookings/", expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                bookings = course_api.rel(:stats).get({course_id: params[:course_id], key: 'bookings'}).value!
                {
                  proctorings: bookings['proctorings'],
                  reactivations: bookings['reactivations'],
                }
              end
            end
          end

          namespace 'social_shares' do
            desc 'Returns course-specific KPIs related to social shares'
            get do
              course_dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/social_shares/", expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                course_social_shares = fetch_metric(name: 'ShareButtonClickCount', course_id: params[:course_id]).value!
                {course_social_shares: course_social_shares&.dig('count')}
              end
            end
          end
        end

        namespace 'item_details' do
          desc 'Statistic endpoints for item stats'

          namespace 'rich_text_links' do
            desc 'Returns a list with all link click counts of a rich text item'
            params do
              requires :item_id, type: String, desc: 'The item UUID'
            end
            get do
              course_item_stats_permission! params[:item_id]

              fetch_metric(name: 'rich_text_links', item_id: params[:item_id]).value!
            end
          end

          namespace 'multiple_choice_or_answer_question' do
            params do
              requires :id, type: String, desc: 'The question UUID'
              optional :exercise_type, type: String, desc: 'The item exercise type'
            end
            get do
              course_item_stats_permission_for_question! params[:id]

              quiz_api.rel(:submission_question_statistic).get({id: params[:id]}).then do |response|
                if params[:exercise_type] == 'survey'
                  response['answers'].sort_by! {|a| a['position'] }
                  response['answers'].each {|a| a['marker_color'] = 'rgb(31, 119, 180, 1)' }
                else
                  response['answers'].sort_by! {|a| [a['correct'] ? 1 : 0, a['submission_count']] }.reverse!
                  response['answers'].each do |a|
                    a['marker_color'] = a['correct'] ? 'rgb(140, 179, 13, 1)' : 'rgb(255, 0, 0, 1)'
                  end
                end
                response
              end.value!
            end
          end

          namespace 'free_text_question' do
            params do
              requires :id, type: String, desc: 'The question UUID'
            end
            get do
              course_item_stats_permission_for_question! params[:id]

              quiz_api.rel(:submission_question_statistic).get({id: params[:id]}).then do |response|
                response['answers']['non_unique_answer_texts'] = response['answers']['non_unique_answer_texts'].map do |k, v|
                  title = k.empty? ? '(empty answer)' : k
                  {title:, value: v}
                end
                response['answers']['non_unique_answer_texts'].sort_by! {|a| a[:value] }.reverse!
                response
              end.value!
            end
          end

          namespace 'essay_question' do
            params do
              requires :id, type: String, desc: 'The question UUID'
            end
            get do
              course_item_stats_permission_for_question! params[:id]

              quiz_api.rel(:submission_question_statistic).get({id: params[:id]}).value!
            end
          end
        end
      end
    end
    # rubocop:enable all
  end
end
