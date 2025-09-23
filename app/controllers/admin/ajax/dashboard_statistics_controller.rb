# frozen_string_literal: true

module Admin
  module Ajax
    class DashboardStatisticsController < Abstract::AjaxController
      require_permission 'global.dashboard.show'

      def age_distribution
        json = Rails.cache.fetch("statistics/dashboard/age_distribution?course_id=#{params[:course_id]}",
          expires_in: 6.hours, race_condition_ttl: 30.seconds) do
          bucket_bounds = [20, 30, 40, 50, 60, 70]

          get_bucket_label = lambda do |age|
            i = bucket_bounds.find_index {|bound| age < bound }
            if i == 0
              "<#{bucket_bounds[0]}"
            elsif i.nil?
              "#{bucket_bounds[-1]}+"
            else
              "#{bucket_bounds[i - 1]}-#{bucket_bounds[i] - 1}"
            end
          end

          create_buckets = lambda do |global_stats, course_stats|
            buckets = [0].concat(bucket_bounds).map do |bound|
              {age_group: get_bucket_label.call(bound), global_count: 0, global_share: 0}
            end
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

          course_stats = nil
          if params[:course_id]
            course_stats = course_api.rel(:course).get({id: params[:course_id]}).value!
              .rel(:students_group).get.value!
              .rel(:stats).get({embed: 'user'}).value!
          end

          create_buckets.call(global_stats, course_stats)
        end

        render json: json
      end

      def client_usage
        if params[:course_id].present?
          json = Rails.cache.fetch(
            'statistics/dashboard/client_usage?' \
            "course_id=#{params[:course_id]}" \
            "&start_date=#{params[:start_date]}" \
            "&end_date=#{params[:end_date]}",
            expires_in: 6.hours, race_condition_ttl: 10.seconds
          ) do
            fetch_metric(
              name: 'client_combination_usage',
              course_id: params[:course_id],
              start_date: params[:start_date].presence || 1.month.ago,
              end_date: params[:end_date].presence || Time.zone.now
            ).value!
          end
        else
          json = Rails.cache.fetch('statistics/dashboard/client_usage', expires_in: 6.hours,
            race_condition_ttl: 10.seconds) do
            fetch_metric(
              name: 'client_combination_usage',
              course_id: params[:course_id],
              start_date: params[:start_date].presence || 1.month.ago,
              end_date: params[:end_date].presence || Time.zone.now
            ).value!
          end
        end

        render json: json
      end
    end
  end
end
