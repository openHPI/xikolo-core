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
        namespace 'platform_dashboard' do
          namespace 'learners_and_enrollments' do
            get do
              global_dashboard_permission!

              Rails.cache.fetch('statistics/platform/learners_and_enrollments/', expires_in: 1.hour, race_condition_ttl: 1.minute) do
                Restify::Promise.new([
                  account_api.rel(:statistics).get,
                  course_api.rel(:stats).get({key: 'global'}),
                ]) do |account_stats, course_stats|
                  total_enrollments = course_stats['platform_enrollments'] + course_stats['platform_enrollment_delta_sum'] + Xikolo.config.global_enrollment_delta
                  confirmed_users = account_stats['confirmed_users'] + Xikolo.config.global_users_delta

                  {
                    confirmed_users:,
                    confirmed_users_last_day:     account_stats['confirmed_users_last_day'],
                    confirmed_users_last_7days:   account_stats['confirmed_users_last_7days'],
                    unconfirmed_users:            account_stats['unconfirmed_users'],
                    unconfirmed_users_last_day:   account_stats['unconfirmed_users_last_day'],
                    deleted_users:                account_stats['users_deleted'],
                    users_with_suspended_email:   account_stats['users_with_suspended_email'],

                    total_enrollments:,
                    total_enrollments_last_day:   course_stats['platform_last_day_enrollments'],
                    total_enrollments_last_7days: course_stats['platform_last_7days_enrollments'],
                    unique_enrollments_last_day:  course_stats['platform_last_day_unique_enrollments'],
                    unenrollments:                course_stats['unenrollments'],
                    custom_completed:             course_stats['platform_custom_completed'],
                    courses_count:                course_stats['courses_count'],

                    courses_per_learner:          total_enrollments.to_f / confirmed_users,
                  }
                end.value!
              end
            end
          end

          namespace 'activity' do
            get do
              global_dashboard_permission!

              fetch_active_users = proc do |start_date, end_date|
                fetch_metric(
                  name: 'active_user_count',
                  start_date:,
                  end_date:
                ).then {|response| response&.dig('active_users') }
              end

              Rails.cache.fetch('statistics/platform/activity/', expires_in: 30.minutes, race_condition_ttl: 1.minute) do
                Restify::Promise.new([
                  fetch_active_users.call(1.hour.ago, Time.zone.now),
                  fetch_active_users.call(24.hours.ago, Time.zone.now),
                  fetch_active_users.call(7.days.ago, Time.zone.now),
                ]) do |active_users_1h, active_users_24h, active_users_7days|
                  {
                    count_1h: active_users_1h,
                    count_24h: active_users_24h,
                    count_7days: active_users_7days,
                  }
                end.value!
              end
            end
          end

          namespace 'certificates' do
            get do
              global_dashboard_permission!

              Rails.cache.fetch('statistics/platform/certificates/', expires_in: 1.hour, race_condition_ttl: 30.seconds) do
                certificates = fetch_metric(name: 'certificates').value!
                {
                  roa_count: certificates['record_of_achievement'],
                  cop_count: certificates['confirmation_of_participation'],
                  qc_count: certificates['qualified_certificate'],
                }
              end
            end
          end

          namespace 'open_badges' do
            get do
              global_dashboard_permission!

              Rails.cache.fetch('statistics/platform/open_badges/', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                Restify::Promise.new(
                  fetch_metric(name: 'badge_download_count'),
                  fetch_metric(name: 'badge_share_count')
                ) do |badge_downloads, badge_shares|
                  {
                    badge_issues: Certificate::OpenBadge.issue_count,
                    badge_downloads: badge_downloads['count'].to_i,
                    badge_shares: badge_shares['count'].to_i,
                  }
                end.value!
              end
            end
          end

          namespace 'tickets' do
            get do
              global_dashboard_permission!

              Rails.cache.fetch('statistics/platform/tickets/', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                tickets = ::Helpdesk::Ticket
                {
                  ticket_count: tickets.count,
                  ticket_count_last_day: tickets.created_last_day.count,
                  avg_tickets_per_day_last_year: tickets.created_last_year.count / 365.to_f,
                }
              end
            end
          end

          namespace 'social_shares' do
            get do
              global_dashboard_permission!

              Rails.cache.fetch('statistics/platform/social_shares/', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                course_social_shares = fetch_metric(name: 'share_button_click_count').value!
                {course_social_shares: course_social_shares&.dig('count')}
              end
            end
          end
        end

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

          namespace 'item_visits' do
            desc 'Returns course-specific item visits'
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'item_visits_count', course_id: params[:course_id]).value!
            end
          end

          namespace 'video_plays' do
            desc 'Returns course-specific video plays'
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'video_play_count', course_id: params[:course_id]).value!
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

          namespace 'total_quiz_performance' do
            desc 'Weighted performance average for all quizzes of a course'
            params do
              requires :type, type: String, desc: 'Either graded or selftest'
            end
            get do
              course_dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/total_quiz_performance/#{params[:type]}/", expires_in: 1.hour, race_condition_ttl: 1.minute) do
                case params[:type]
                  when 'graded'
                    types = %w[main bonus]
                  when 'selftest'
                    types = %w[selftest]
                  else
                    next
                end

                promises = []

                Xikolo.paginate(
                  course_api.rel(:items).get({
                    course_id: params[:course_id],
                    was_available: true,
                    content_type: 'quiz',
                    exercise_type: types.join(','),
                  })
                ) do |quiz|
                  promises.append quiz_api.rel(:submission_statistic).get({id: quiz['content_id']})
                end

                quiz_stats = Restify::Promise.new(promises).value!

                total_avg_points = 0
                total_max_points = 0

                quiz_stats.each do |qs|
                  if qs['avg_points']
                    total_avg_points += qs['avg_points']
                    total_max_points += qs['max_points']
                  end
                end

                if total_max_points > 0
                  total_avg_points / total_max_points
                end
              end
            end
          end

          namespace 'forum' do
            get do
              course_dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/forum/", expires_in: 1.hour, race_condition_ttl: 10.seconds) do
                Restify::Promise.new(
                  pinboard_api.rel(:statistic).get({id: params[:course_id]}),
                  fetch_metric(name: 'forum_activity', course_id: params[:course_id]),
                  fetch_metric(name: 'forum_write_activity', course_id: params[:course_id])
                ) do |forum_statistics, forum_activity, forum_write_activity|
                  {
                    forum_statistics:,
                    forum_activity:,
                    forum_write_activity:,
                  }
                end.value!
              end
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

          namespace 'historic_data' do
            get do
              course_dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/course/#{params[:course_id]}/historic_data/", expires_in: 1.hour, race_condition_ttl: 30.seconds) do
                course = course_api.rel(:course).get({id: params[:course_id]}).value!

                end_date =
                  if course['end_date'].blank? || DateTime.parse(course['end_date']).future?
                    DateTime.now
                  else # end_date is in the past
                    DateTime.parse(course['end_date']) + 12.weeks
                  end

                course_statistics = lanalytics_api.rel(:course_statistics).get({
                  course_id: params[:course_id],
                  historic_data: true,
                  start_date: course['created_at'],
                  end_date:,
                }).value!

                course_statistics.map do |stats|
                  {
                    timestamp: stats['updated_at'].to_date,
                    total_enrollments: stats['total_enrollments'],
                    current_enrollments: stats['current_enrollments'],
                    enrollments_last_day: stats['enrollments_last_day'],
                    new_users: stats['new_users'],
                    no_shows: stats['no_shows'],
                    active_users_last_day: stats['active_users_last_day'],
                    active_users_last_7days: stats['active_users_last_7days'],
                    posts: stats['posts'],
                    threads: stats['threads'],
                    posts_in_collab_spaces: stats['posts_in_collab_spaces'],
                    threads_in_collab_spaces: stats['threads_in_collab_spaces'],
                    helpdesk_tickets: stats['helpdesk_tickets'],
                  }
                end
              end
            end
          end
        end

        namespace 'dashboard' do
          desc 'Statistic endpoints shared by platform and course dashboard'

          params do
            optional :course_id, type: String, desc: 'The course UUID'
          end

          namespace 'age_distribution' do
            get do
              dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/dashboard/age_distribution/#{checksum(for_hash: params)}", expires_in: 6.hours, race_condition_ttl: 30.seconds) do
                bucket_bounds = [20, 30, 40, 50, 60, 70]
                get_bucket_label = proc do |age|
                  i = bucket_bounds.find_index {|bound| age < bound }
                  if i == 0
                    "<#{bucket_bounds[0]}"
                  elsif i.nil?
                    "#{bucket_bounds[-1]}+"
                  else
                    "#{bucket_bounds[i - 1]}-#{bucket_bounds[i] - 1}"
                  end
                end
                create_buckets = proc do |global_stats, course_stats|
                  buckets = [0].concat(bucket_bounds).map {|bound| {age_group: get_bucket_label.call(bound), global_count: 0, global_share: 0} }
                  global_total = global_stats['user']['age'].values.sum
                  global_stats['user']['age'].each do |age, count|
                    label = get_bucket_label.call(age.to_i)
                    b = buckets.find {|bucket| bucket[:age_group] == label }
                    b[:global_count] += count
                    b[:global_share] += count / global_total.to_f
                  end
                  if course_stats
                    buckets.each do |b|
                      b[:course_count] = 0
                      b[:course_share] = 0
                    end
                    course_total = course_stats['user']['age'].values.sum
                    course_stats['user']['age'].each do |age, count|
                      label = get_bucket_label.call(age.to_i)
                      b = buckets.find {|bucket| bucket[:age_group] == label }
                      b[:course_count] += count
                      b[:course_share] += count / course_total.to_f
                    end
                  end
                  buckets
                end

                global_stats = account_api.rel(:group).get({id: 'all'}).value!
                  .rel(:stats).get({embed: 'user'}).value!

                if params[:course_id]
                  course_stats = course_api.rel(:course).get({id: params[:course_id]}).value!
                    .rel(:students_group).get.value!
                    .rel(:stats).get({embed: 'user'}).value!
                  create_buckets.call(global_stats, course_stats)
                else
                  create_buckets.call(global_stats, nil)
                end
              end
            end
          end

          namespace 'client_usage' do
            params do
              optional :start_date, type: String, desc: 'The start date, default is one month ago'
              optional :end_date,   type: String, desc: 'The end date, default is now'
            end
            get do
              dashboard_permission! params[:course_id]

              Rails.cache.fetch(
                "statistics/dashboard/client_usage/#{checksum(for_hash: params)}",
                expires_in: 6.hours,
                race_condition_ttl: 10.seconds
              ) do
                fetch_metric(**{
                  name: 'client_combination_usage',
                  course_id: params[:course_id],
                  start_date: params[:start_date].presence || 1.month.ago,
                  end_date: params[:end_date].presence || Time.zone.now,
                }.compact).value!
              end
            end
          end

          namespace 'custom_field' do
            params do
              requires :name, type: String, desc: 'The name of the custom field'
            end
            get do
              dashboard_permission! params[:course_id]

              custom_field = Rails.cache.fetch(
                "statistics/dashboard/custom_field/#{checksum(for_hash: params.slice(:course_id, :name))}",
                expires_in: 6.hours,
                race_condition_ttl: 10.seconds
              ) do
                course = course_api.rel(:course).get({id: params[:course_id]}).value!
                course.rel(:students_group).get.value!.rel(:profile_field_stats).get({id: params[:name]}).value!
              end

              custom_field.fetch('aggregation').map do |k, v|
                {
                  field_value: I18n.t(:"dashboard.profile.settings.#{custom_field['name']}.#{k}"),
                  value_count: v,
                }
              end
            end
          end

          namespace 'weekday_activity' do
            get do
              dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/dashboard/weekday_activity/#{checksum(for_hash: params)}", expires_in: 6.hours, race_condition_ttl: 10.seconds) do
                start_date, end_date =
                  if params[:course_id].present?
                    course = course_api.rel(:course).get({id: params[:course_id]}).value!

                    start_date = Time.zone.parse(course['start_date'] || course['created_at'])

                    end_date =
                      if course['end_date'].blank?
                        start_date = [start_date, 1.month.ago].max

                        Time.zone.now
                      elsif Time.zone.parse(course['end_date']).future?
                        Time.zone.now
                      else # end_date is in the past
                        Time.zone.parse(course['end_date'])
                      end

                    [start_date, end_date]
                  else
                    [1.month.ago, Time.zone.now]
                  end

                fetch_metric(**{
                  name: 'active_users_by_weekday',
                  course_id: params[:course_id],
                  start_date: start_date.beginning_of_day,
                  end_date:,
                }.compact).value!
              end
            end
          end
        end

        namespace 'details' do
          desc 'Statistic endpoints for separate statistic pages'

          namespace 'geo' do
            params do
              optional :course_id, type: String, desc: 'The course UUID'
              optional :start_date, type: String, desc: 'The start date, default is one month ago'
              optional :end_date,   type: String, desc: 'The end date, default is now'
            end

            namespace 'countries' do
              desc 'Return users per country'
              get do
                dashboard_permission! params[:course_id]

                Rails.cache.fetch("statistics/geo/countries/#{checksum(for_hash: params)}", expires_in: 6.hours, race_condition_ttl: 10.seconds) do
                  fetch_metric(**{
                    name: 'top_countries',
                    course_id: params[:course_id],
                    start_date: params[:start_date].presence || 1.month.ago,
                    end_date: params[:end_date].presence || Time.zone.now,
                  }.compact).value!
                end
              end
            end

            namespace 'cities' do
              desc 'Return users per city (top 100 cities)'
              get do
                dashboard_permission! params[:course_id]

                Rails.cache.fetch("statistics/geo/cities/#{checksum(for_hash: params)}", expires_in: 6.hours, race_condition_ttl: 10.seconds) do
                  fetch_metric(**{
                    name: 'top_cities',
                    course_id: params[:course_id],
                    start_date: params[:start_date].presence || 1.month.ago,
                    end_date: params[:end_date].presence || Time.zone.now,
                  }.compact).value!
                end
              end
            end
          end

          namespace 'daily_activity' do
            desc 'Return the number of active users per day and hour'
            params do
              optional :course_id, type: String, desc: 'The course UUID'
            end
            get do
              dashboard_permission! params[:course_id]

              Rails.cache.fetch("statistics/dashboard/details/daily_activity/#{checksum(for_hash: params)}", expires_in: 30.minutes, race_condition_ttl: 10.seconds) do
                start_date, end_date =
                  if params[:course_id].present?
                    course = course_api.rel(:course).get({id: params[:course_id]}).value!

                    start_date = Time.zone.parse(course['start_date'] || course['created_at'])

                    end_date =
                      if course['end_date'].blank?
                        start_date = [start_date, 60.days.ago].max

                        Time.zone.now
                      elsif Time.zone.parse(course['end_date']).future?
                        Time.zone.now
                      else # end_date is in the past
                        Time.zone.parse(course['end_date'])
                      end

                    [start_date, end_date]
                  else
                    [60.days.ago, Time.zone.now]
                  end

                fetch_metric(**{
                  name: 'active_users_by_day',
                  course_id: params[:course_id],
                  start_date: start_date.beginning_of_day,
                  end_date:,
                }.compact).value!
              end
            end
          end

          namespace 'referrers' do
            desc 'Return the list of referrers with counts'
            params do
              optional :course_id,   type: String,  desc: 'The course UUID'
              optional :group_hosts, type: Boolean, desc: 'Groups referrer URLs by host names'
              optional :top,         type: Integer, desc: 'Limits the number of returned referrers'
            end
            get do
              dashboard_permission! params[:course_id]

              break if !metrics_available?('TopReferrers') || (params[:top].present? && !metrics_available?('ReferrerCount'))

              response = fetch_metric(**{
                name: 'TopReferrers',
                group_hosts: params[:group_hosts],
                course_id: params[:course_id],
              }.compact).value!

              result = response.map {|url, count| {site: url, count:} }
              unless params[:top].nil?
                response = fetch_metric(**{
                  name: 'ReferrerCount',
                  course_id: params[:course_id],
                }.compact).value!
                total_count = response['count']

                result = result.first params[:top]
                other_count = total_count - result.sum {|item| item[:count] }
                result << {site: 'Other', count: other_count} if other_count > 0
              end
              result
            end
          end

          namespace 'social_shares' do
            desc 'Return the list of course share services with click counts for the last 7 and 30 days'
            params do
              optional :course_id, type: String, desc: 'The course UUID'
            end
            get do
              dashboard_permission! params[:course_id]

              break unless metrics_available? 'ShareButtonClicks'

              fetch_share_button_clicks = proc do |start_date, end_date|
                fetch_metric(**{
                  name: 'ShareButtonClicks',
                  start_date:,
                  end_date:,
                  course_id: params[:course_id],
                }.compact).then {|response| response.map {|service, clicks| {service:, clicks:} } }
              end

              Restify::Promise.new([
                fetch_share_button_clicks.call(DateTime.now - 7.days, DateTime.now),
                fetch_share_button_clicks.call(DateTime.now - 30.days, DateTime.now),
                fetch_share_button_clicks.call,
              ]) do |last_7_days, last_30_days, total|
                {
                  last_7_days:,
                  last_30_days:,
                  total:,
                }
              end.value!
            end
          end

          namespace 'item_visits' do
            namespace 'top_items' do
              desc 'Returns a list with all course items and their visits'
              params do
                requires :course_id, type: String, desc: 'The course UUID'
              end
              get do
                course_dashboard_permission! params[:course_id]

                items = []
                Xikolo.paginate(
                  course_api.rel(:items).get({course_id: params[:course_id]})
                ) do |item|
                  items << item
                end

                sections = []
                Xikolo.paginate(
                  course_api.rel(:sections).get({
                    course_id: params[:course_id],
                    include_alternatives: true,
                  })
                ) do |section|
                  sections << section
                end

                visits = fetch_metric(name: 'top_items', course_id: params[:course_id]).value!

                visits.each_with_object([]) do |visit, array|
                  item = items.find {|i| i['id'] == visit['item_id'] }

                  next unless item

                  section = sections.find {|s| s['id'] == item['section_id'] }

                  next unless section

                  visit['item_title'] = item['title']
                  visit['item_content_type'] = item['content_type']&.humanize
                  visit['item_exercise_type'] = item['exercise_type']&.humanize
                  visit['position'] = "#{section['position']}.#{item['position']}"
                  array << visit
                end
              end
            end

            namespace 'top_item_types' do
              desc 'Returns a list with all item types and their visits for a course'
              params do
                requires :course_id, type: String, desc: 'The course UUID'
              end
              get do
                course_dashboard_permission! params[:course_id]

                items = []
                Xikolo.paginate(
                  course_api.rel(:items).get({course_id: params[:course_id]})
                ) do |item|
                  items << item
                end

                visits = fetch_metric(name: 'top_items', course_id: params[:course_id]).value!

                visits.each_with_object([]) do |visit, array|
                  item = items.find {|i| i['id'] == visit['item_id'] }

                  next unless item

                  if item['exercise_type'].present?
                    type = item['exercise_type'].humanize
                  else
                    type = item['content_type'].humanize
                  end

                  a = array.find {|val| val['type'] == type }
                  if a
                    a['visits'] += visit['visits']
                    a['count'] += 1
                  else
                    array << {
                      'type' => type,
                      'visits' => visit['visits'],
                      'count' => 1,
                    }
                  end
                end.sort_by {|a| a['visits'] }.reverse
              end
            end
          end

          namespace 'videos' do
            desc 'Returns a list with all video items and their statistics'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
            end
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'video_statistics', course_id: params[:course_id]).value!
            end
          end

          namespace 'downloads' do
            desc 'Returns a list with all course video items and their downloads'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
            end
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'download_count', course_id: params[:course_id]).value!
            end
          end

          namespace 'rich_text_link_clicks' do
            desc 'Returns a list with all course rich text items and their link clicks'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
            end
            get do
              course_dashboard_permission! params[:course_id]

              fetch_metric(name: 'rich_text_link_click_count', course_id: params[:course_id]).value!
            end
          end

          namespace 'pinboard' do
            namespace 'teaching_team' do
              desc 'Return the list of teaching team and their pinboard activity'
              params do
                requires :course_id, type: String, desc: 'The course UUID'
              end
              get do
                course_dashboard_permission! params[:course_id]

                if Xikolo.config.beta_features['teaching_team_pinboard_activity']
                  pinboard_api.rel(:statistics).get({
                    for_teaching_team: true,
                    course_id: params[:course_id],
                  }).value
                end
              end
            end

            namespace 'most_active' do
              desc 'Return the list of the most active pinboard users'
              params do
                requires :course_id, type: String, desc: 'The course UUID'
              end
              get do
                course_dashboard_permission! params[:course_id]

                if Xikolo.config.beta_features['teaching_team_pinboard_activity']
                  pinboard_api.rel(:statistics).get({
                    most_active: 20,
                    course_id: params[:course_id],
                  }).value
                end
              end
            end
          end

          namespace 'quiz' do
            desc 'Returns a list with statistics of all course quizzes'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
              requires :type, type: String, desc: 'Either graded, selftest or survey'
              optional :embed, type: String, desc: 'Options: avg_submit_duration, box_plot_distributions'
            end
            get do
              course_dashboard_permission! params[:course_id]

              case params[:type]
                when 'graded'
                  types = %w[main bonus]
                when 'selftest'
                  types = %w[selftest]
                when 'survey'
                  types = %w[survey]
                else
                  next
              end

              embed = params[:embed]
                &.split(',')
                &.select do |param|
                %w[
                  avg_submit_duration
                  box_plot_distributions
                ].include? param
              end

              promises = []

              sections = []
              Xikolo.paginate(
                course_api.rel(:sections).get({
                  course_id: params[:course_id],
                  include_alternatives: true,
                })
              ) do |section|
                sections << section
              end

              Xikolo.paginate(
                course_api.rel(:items).get({
                  course_id: params[:course_id],
                  was_available: true,
                  content_type: 'quiz',
                  exercise_type: types.join(','),
                })
              ) do |quiz|
                promises.append(
                  quiz:,
                  promise: quiz_api.rel(:submission_statistic).get(
                    {
                      id: quiz['content_id'],
                      embed: embed.join(','),
                    }.compact
                  )
                )
              end

              promises.map do |e|
                quiz = e[:quiz]
                stats = e[:promise].value!

                section = sections.find {|sec| sec['id'] == quiz['section_id'] }

                max_points = stats['max_points'].to_f
                avg_points = stats['avg_points'].to_f
                avg_performance = max_points > 0 ? avg_points / max_points : nil

                # prepare values to be visualized as box plot
                box_plot_values = stats['box_plot_distributions']&.values
                if box_plot_values
                  # Insert median two times to ensure correct display. There are
                  # edge-cases when the chart lib needs that. Very specific to
                  # the view implementation, which is why we do it here and not
                  # in the service.
                  box_plot_values << stats.dig('box_plot_distributions', 'median')
                  box_plot_values.sort!
                end

                {
                  title: quiz['title'],
                  position: "#{section['position']}.#{quiz['position']}",
                  item_id: quiz['id'],
                  quiz_id: quiz['content_id'],
                  submission_count: stats['total_submissions'],
                  submission_user_count: stats['total_submissions_distinct'],
                  avg_performance:,
                  unlimited_time: stats['unlimited_time'],
                  avg_submit_duration: Duration.new(stats['avg_submit_duration']).to_s,
                  box_plot_values:,
                }.compact
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

          namespace 'video_events' do
            params do
              requires :item_id, type: String, desc: 'The video item UUID'
            end
            get do
              course_item_stats_permission! params[:item_id]

              fetch_metric(
                name: 'video_events_timeline',
                item_id: params[:item_id]
              ).value!
            end
          end

          namespace 'result_submissions_over_time' do
            params do
              requires :id, type: String, desc: 'The item UUID'
            end
            get do
              course_item_stats_permission! params[:id]

              course_api
                .rel(:item).get({id: params[:id]}).value!
                .rel(:statistics).get({only: 'submissions_over_time'}).value!
            end
          end

          namespace 'quiz_submissions_over_time' do
            params do
              requires :id, type: String, desc: 'The quiz UUID'
            end
            get do
              course_item_stats_permission_for_quiz! params[:id]

              quiz_api.rel(:submission_statistic).get({
                id: params[:id],
                only: 'submissions_over_time',
              }).value!
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
