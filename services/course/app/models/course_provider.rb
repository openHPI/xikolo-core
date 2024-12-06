# frozen_string_literal: true

class CourseProvider < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :provider_type, presence: true
  validates :config, presence: true

  def self.sync(course_id)
    CourseProvider
      .where(enabled: true)
      .find_each do |provider|
        CourseProviderWorker
          .perform_async(
            provider.name,
            provider.provider_type,
            provider.config,
            course_id
          )
      end
  end

  def self.sync?(course)
    (course.status != 'preparation' || changed_to_preparation?(course)) &&
      !course.invite_only &&
      course.external_course_url.blank? &&
      course.groups.blank?
  end

  def self.changed_to_preparation?(course)
    course.previous_changes.key?(:status) &&
      (course.previous_changes[:status] == %w[active preparation] ||
      course.previous_changes[:status] == %w[archive preparation])
  end
end
