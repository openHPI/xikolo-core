# frozen_string_literal: true

module CourseService
class CourseProvider < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :course_providers

  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true
  validates :config, presence: true

  def self.sync(course_id)
    CourseProvider
      .where(enabled: true)
      .find_each do |provider|
        CourseProviderJob
          .perform_later(
            provider.name,
            provider.provider_type,
            provider.config,
            course_id
          )
      end
  end

  def self.sync?(course)
    (course.published? || published_changed?(course)) &&
      !course.invite_only &&
      course.external_course_url.blank? &&
      course.groups.blank?
  end

  def self.published_changed?(course)
    course.published_previously_changed?(from: true, to: false)
  end
end
end
