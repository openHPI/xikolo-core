# frozen_string_literal: true

module CourseService
  class Metadata < ApplicationRecord
    self.table_name = 'metadata'

    belongs_to :course, class_name: 'CourseService::Course'

    validates :name, :version, presence: true
    validate :valid_json_data?

    VERSION = 'urn:moochub:3.0'

    module TYPE
      SKILLS = 'skills'
      EDUCATIONAL_ALIGNMENT = 'educational_alignment'
      LICENSE = 'license'
    end

    module SCHEMA
      SKILLS = CourseService::Engine.root.join('app', 'models', 'course_service', 'schemas', 'metadata', 'skills.json')
      EDUCATIONAL_ALIGNMENT = CourseService::Engine.root.join('app', 'models', 'course_service', 'schemas', 'metadata',
        'educational_alignment.json')
      LICENSE = CourseService::Engine.root.join('app', 'models', 'course_service', 'schemas', 'metadata',
        'license.json')
    end

    class << self
      def resolve(course_id, name, version)
        find_by!(course_id:, name:, version:).data
      rescue ActiveRecord::RecordNotFound
        []
      end
    end

    private

    def valid_json_data?
      if name == TYPE::SKILLS
        data.each do |e|
          JSON::Validator.validate!(File.read(SCHEMA::SKILLS), e)
        end
      end

      if name == TYPE::EDUCATIONAL_ALIGNMENT
        data.each do |e|
          JSON::Validator.validate!(File.read(SCHEMA::EDUCATIONAL_ALIGNMENT), e)
        end
      end

      if name == TYPE::LICENSE
        data.each do |e|
          JSON::Validator.validate!(File.read(SCHEMA::LICENSE), e)
        end
      end
    end
  end
end
