# frozen_string_literal: true

module Admin
  module Statistics
    class MostActive < ApplicationOperation
      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        most_active_data = fetch_forum_data(@course_id)
        return {most_active_data: []} if most_active_data.blank?

        {
          headers: {
            user: I18n.t('admin.statistics.pinboard.member_header'),
            posts: I18n.t('admin.statistics.pinboard.posts_header'),
            threads: I18n.t('admin.statistics.pinboard.threads_header'),
          },
          most_active_data: filter_admins(most_active_data),
        }
      rescue StandardError => e
        ::Sentry.capture_exception(e, extra: {course_id: @course_id, operation: 'MostActive#call'})
        {most_active_data: []}
      end

      private

      def fetch_forum_data(course_id)
        Xikolo.api(:pinboard).value!.rel(:statistics).get({
          most_active: 20,
          course_id:,
        }).value!
      end

      def filter_admins(data)
        group_id = AccountService::Group.find_by(name: 'xikolo.admins').id
        admin_user_ids = AccountService::Membership.where(group_id: group_id).pluck(:user_id)

        data.reject do |row|
          admin_user_ids.include?(row['user']['id'])
        end.first(5)
      end
    end
  end
end
