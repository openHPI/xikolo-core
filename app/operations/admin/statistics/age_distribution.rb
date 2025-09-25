# frozen_string_literal: true

module Admin
  module Statistics
    class AgeDistribution < ApplicationOperation
      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        buckets = fetch_age_distribution(@course_id)
        buckets.map do |b|
          {
            'age_group' => b[:age_group],
            'global_count' => b[:global_count],
            'global_share' => percentage(b[:global_share]),
          }.merge(course_columns_for(b))
        end
      end

      private

      def percentage(value)
        return '0%' unless value

        "#{(value.to_f * 100).round(2)}%"
      end

      def course_columns_for(bucket)
        if bucket.key?(:course_count) || bucket.key?(:course_share)
          {
            'course_count' => bucket[:course_count] || 0,
            'course_share' => percentage(bucket[:course_share] || 0),
          }
        else
          {}
        end
      end

      def fetch_age_distribution(course_id)
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

        buckets = [0].concat(bucket_bounds).map do |bound|
          {age_group: get_bucket_label.call(bound), global_count: 0, global_share: 0}
        end

        global_stats = Xikolo.api(:account).value!
          .rel(:group).get({id: 'all'}).value!
          .rel(:stats).get({embed: 'user'}).value!

        global_total = global_stats['user']['age'].values.sum
        global_stats['user']['age'].each do |age, count|
          label = get_bucket_label.call(age.to_i)
          b = buckets.find {|bucket| bucket[:age_group] == label }
          b[:global_count] += count
          b[:global_share] += count / global_total.to_f
        end

        if course_id
          buckets.each do |b|
            b[:course_count] = 0
            b[:course_share] = 0
          end
          course_stats = Xikolo.api(:course).value!
            .rel(:course).get({id: course_id}).value!
            .rel(:students_group).get.value!
            .rel(:stats).get({embed: 'user'}).value!
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
    end
  end
end
