# frozen_string_literal: true

module Lti
  class Exercise < ::ApplicationRecord
    self.table_name = 'lti_exercises'

    DEFAULT_WEIGHT = 1

    attribute :instructions, Xikolo::S3::Markup.new(
      uploads: {purpose: 'lti_exercise_instructions', content_type: 'image/*'}
    )

    validates :lti_provider_id, presence: true

    belongs_to :provider,
      optional: true,
      class_name: 'Lti::Provider',
      foreign_key: :lti_provider_id,
      inverse_of: :exercises

    has_one :item,
      class_name: 'CourseService::Item',
      as: :content,
      dependent: :restrict_with_exception

    has_many :gradebooks,
      class_name: 'Lti::Gradebook',
      dependent: :destroy,
      foreign_key: :lti_exercise_id,
      inverse_of: :exercise

    def score_for(user_id)
      gradebooks.find_by(user_id:).try(:highest_grade).try(:score)
    end

    def deleted_provider?
      persisted? && reload_provider.nil?
    end

    def weight
      self[:weight] || DEFAULT_WEIGHT
    end

    def locked?
      lock_submissions_at&.past?
    end

    def custom_parameters
      [provider.custom_fields, custom_fields].reduce({}) do |memo, custom_fields|
        memo.merge Rack::Utils.parse_nested_query(custom_fields)
      end
    end

    def launch_for(user)
      Lti::ToolLaunch.new(self, user)
    end
  end
end
