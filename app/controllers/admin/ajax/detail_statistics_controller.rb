# frozen_string_literal: true

module Admin
  module Ajax
    class DetailStatisticsController < Abstract::AjaxController
      require_permission 'global.dashboard.show'

      def countries
        data = Rails.cache.fetch("statistics/geo/countries?#{query}", expires_in: 6.hours,
          race_condition_ttl: 10.seconds) do
          fetch_metric(**{
            name: 'top_countries',
            course_id: params[:course_id],
            start_date: params[:start_date].presence || 1.month.ago,
            end_date: params[:end_date].presence || Time.zone.now,
          }.compact).value!
        end

        render json: data
      end

      def cities
        data = Rails.cache.fetch("statistics/geo/cities#{query}", expires_in: 6.hours,
          race_condition_ttl: 10.seconds) do
          fetch_metric(**{
            name: 'top_cities',
            course_id: params[:course_id],
            start_date: params[:start_date].presence || 1.month.ago,
            end_date: params[:end_date].presence || Time.zone.now,
          }.compact).value!
        end

        render json: data
      end

      def top_item_types
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

        render json: visits
      end

      def videos
        data = fetch_metric(name: 'video_statistics', course_id: params[:course_id]).value!

        render json: data
      end

      def most_active
        if Xikolo.config.beta_features['teaching_team_pinboard_activity']
          data = pinboard_api.rel(:statistics).get({
            most_active: 20,
            course_id: params[:course_id],
          }).value

          render json: data
        end
      end

      private

      def query
        params.permit(:course_id, :start_date, :end_date).to_query
      end
    end
  end
end
