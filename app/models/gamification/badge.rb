# frozen_string_literal: true

module Gamification
  class Badge < ::ApplicationRecord
    default_scope { order(level: :desc) }

    belongs_to :course, class_name: 'CourseService::Course', optional: true
    belongs_to :user, class_name: 'AccountService::User'

    class << self
      def types
        @types ||= YAML.load_file(File.expand_path('./badge_types.yml', __dir__))
      end
    end
  end
end
