# frozen_string_literal: true

module Xikolo
  module V2
    class Base < Grape::API::Instance
      version 'v2', using: :path

      get do
        content_type 'application/vnd.api+json'
        {
          data: nil,
          links: {},
        }.to_json
      end

      mount TokenAPI

      mount CourseAPI
      mount PreferenceAPI
      mount StatisticsAPI
      mount PinboardAPI
      mount NewsStatisticAPI
      mount LearningInsightsAPI

      def self.json_api_endpoints
        @json_api_endpoints ||= {}
      end

      def self.mount_json_api_endpoint(path, klass)
        namespace path do
          mount klass
        end

        json_api_endpoints[path] = klass
      end

      mount_json_api_endpoint 'announcements', V2::News::Announcements
      mount_json_api_endpoint 'channels', V2::Courses::Channels
      mount_json_api_endpoint 'clusters', V2::Classifiers::Clusters
      mount_json_api_endpoint 'courses', V2::Courses::Courses
      mount_json_api_endpoint 'course-dates', V2::Courses::Dates
      mount_json_api_endpoint 'course-features', V2::Features::CourseFeatures
      mount_json_api_endpoint 'course-items', V2::Courses::Items
      mount_json_api_endpoint 'course-progresses', V2::Courses::CourseProgresses
      mount_json_api_endpoint 'course-sections', V2::Courses::Sections
      mount_json_api_endpoint 'documents', V2::Documents::Documents
      mount_json_api_endpoint 'enrollments', V2::Courses::Enrollments
      mount_json_api_endpoint 'experiment-assignments', V2::Features::ExperimentAssignments
      mount_json_api_endpoint 'features', V2::Features::Features
      mount_json_api_endpoint 'last-visits', V2::Courses::LastVisits
      mount_json_api_endpoint 'lti-exercises', V2::CourseItems::LtiExercises
      mount_json_api_endpoint 'pinboard-topics', V2::Pinboard::Topics
      mount_json_api_endpoint 'platform-events', V2::Activity::PlatformEvents
      mount_json_api_endpoint 'quizzes', V2::Quiz::Quizzes
      mount_json_api_endpoint 'quiz-questions', V2::Quiz::Questions
      mount_json_api_endpoint 'quiz-submissions', V2::Quiz::Submissions
      mount_json_api_endpoint 'repetition-suggestions', V2::Courses::RepetitionSuggestions
      mount_json_api_endpoint 'rich-texts', V2::CourseItems::RichTexts
      mount_json_api_endpoint 'section-progresses', V2::Courses::SectionProgresses
      mount_json_api_endpoint 'subtitle-cues', V2::Subtitles::Cues
      mount_json_api_endpoint 'subtitle-tracks', V2::Subtitles::Tracks
      mount_json_api_endpoint 'tickets', V2::Helpdesk::Tickets
      mount_json_api_endpoint 'tracking-events', V2::Tracking::TrackingEvents
      mount_json_api_endpoint 'users', V2::User::Users
      mount_json_api_endpoint 'videos', V2::CourseItems::Videos
    end
  end
end
