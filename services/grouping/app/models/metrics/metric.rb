# frozen_string_literal: true

module Metrics
  class Metric < ::ApplicationRecord
    # Map "type" column values to concrete subclasses.
    # NOTE: This can be used to map obsolete values to newer classes, or when
    # renaming models.
    STI_TYPE_TO_CLASS = {
      'AvgSessionDuration' => '::Metrics::AvgSessionDuration',
      'CourseActivity' => '::Metrics::CourseActivity',
      'CoursePoints' => '::Metrics::CoursePoints',
      'EnrollmentsMetric' => '::Metrics::EnrollmentsMetric',
      'PinboardActivity' => '::Metrics::PinboardActivity',
      'PinboardPostingActivity' => '::Metrics::PinboardPostingActivity',
      'PinboardWatchCount' => '::Metrics::PinboardWatchCount',
      'QuestionResponseTime' => '::Metrics::QuestionResponseTime',
      'Sessions' => '::Metrics::Sessions',
      'TotalSessionDuration' => '::Metrics::TotalSessionDuration',
      'UserEnrollmentCount' => '::Metrics::UserEnrollmentCount',
      'VideoPlayerNavigationCount' => '::Metrics::VideoPlayerNavigationCount',
      'VideoPlayerSeekCount' => '::Metrics::VideoPlayerSeekCount',
      'VideoVisitCount' => '::Metrics::VideoVisitCount',
      'VisitCount' => '::Metrics::VisitCount',
    }.freeze

    # What "type" should be used when storing each subclass?
    STI_CLASS_TO_TYPE = {
      'Metrics::AvgSessionDuration' => 'AvgSessionDuration',
      'Metrics::CourseActivity' => 'CourseActivity',
      'Metrics::CoursePoints' => 'CoursePoints',
      'Metrics::EnrollmentsMetric' => 'EnrollmentsMetric',
      'Metrics::PinboardActivity' => 'PinboardActivity',
      'Metrics::PinboardPostingActivity' => 'PinboardPostingActivity',
      'Metrics::PinboardWatchCount' => 'PinboardWatchCount',
      'Metrics::QuestionResponseTime' => 'QuestionResponseTime',
      'Metrics::Sessions' => 'Sessions',
      'Metrics::TotalSessionDuration' => 'TotalSessionDuration',
      'Metrics::UserEnrollmentCount' => 'UserEnrollmentCount',
      'Metrics::VideoPlayerNavigationCount' => 'VideoPlayerNavigationCount',
      'Metrics::VideoPlayerSeekCount' => 'VideoPlayerSeekCount',
      'Metrics::VideoVisitCount' => 'VideoVisitCount',
      'Metrics::VisitCount' => 'VisitCount',
    }.freeze

    has_and_belongs_to_many :user_tests
    has_many :trial_results

    after_initialize :set_distribution, :set_name

    class << self
      ##
      # Resolve the concrete subclass to use for a value of the type column.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#find_sti_class.
      def find_sti_class(type_name)
        if (cls = STI_TYPE_TO_CLASS[type_name])
          ::ActiveSupport::Dependencies.constantize(cls)
        else
          raise SubclassNotFound.new("Unsupported record type: #{type_name}")
        end
      end

      ##
      # Determine the type identifier to use as "type" when storing a concrete subclass.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#sti_name.
      def sti_name
        STI_CLASS_TO_TYPE.fetch(name)
      end

      def available_metrics
        Rails.application.eager_load!
        descendants.select(&:show)
      end

      def show
        false
      end
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Metric instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Metric')
    end

    def to_param
      id
    end

    def set_distribution
      self.distribution ||= :normal
    end

    def set_name
      self.name ||= 'Metric'
    end

    def delayed?
      (wait_interval || 0).positive?
    end
  end
end
