# frozen_string_literal: true

module Course
  class Richtext < ApplicationRecord
    attribute :text, Xikolo::S3::Markup.new(
      uploads: {purpose: 'course_richtext'}
    )

    belongs_to :course, class_name: 'Course::Course'
    has_one :item,
      class_name: 'Course::Item',
      as: :content,
      dependent: :restrict_with_exception

    after_commit :delete_s3_objects!, on: :destroy

    def self.referenced?(uri)
      ::Course::Course.exists?(['description LIKE ?', "%#{uri}%"]) ||
        ::Course::Richtext.exists?(['text LIKE ?', "%#{uri}%"])
    end

    def as_api_v2
      @api_v2 ||= ::Course::Richtext::APIV2.new(self).as_json # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    # Per default, ActiveRecord maps a parent and a child in a polymorphic association based on the parents class
    # name, e.g. `Course::Richtext`, and stores it in a polymorphic type column, here `content_type`.
    # As we stored custom values in the `content_type` column before utilising polymorphic assocations, we need to
    # override the default polymorphic_name.
    def self.polymorphic_name
      'rich_text'
    end

    private

    def delete_s3_objects!
      Xikolo::S3.extract_file_refs(text).each do |uri|
        S3FileDeletionJob.set(wait: 1.hour).perform_later(uri) unless ::Course::Richtext.referenced?(uri)
      end
    end
  end
end
