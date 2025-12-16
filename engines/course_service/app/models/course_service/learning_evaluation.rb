# frozen_string_literal: true

module CourseService
module LearningEvaluation # rubocop:disable Layout/IndentationWidth
  def self.by_params(params)
    # The old implementation was requested.
    if params[:learning_evaluation] == 'true'
      # We can soft-launch the new implementation with a config flag.
      case config['read']
        # true: Force it for everyone!
        when true
          Persisted.new
        # 0..100: Always use dynamic learning evaluation, but compare with
        # persisted learning evaluation for the defined percentage of users
        # and report the results if there are differences.
        when 0..100
          SoftLaunch.new config['read'], params:
        else
          Dynamic.new
      end
    # The new implementation (faster, based on precalculated data) was requested.
    elsif params[:evaluated]
      Persisted.new
    # Nothing was requested - don't run anything.
    else
      Null.new
    end
  end

  def self.config
    value = Xikolo.config.persisted_learning_evaluation
    value.is_a?(Hash) ? value : {'write' => value}
  end

  class Dynamic
    def call(enrollments)
      Enrollment.with_learning_evaluation(enrollments).tap do |relation|
        relation.includes! :course
      end
    end
  end

  class Persisted
    def call(enrollments)
      enrollments.with_evaluation
    end
  end

  class SoftLaunch
    include Scientist

    def initialize(percentage, params:)
      @percentage = percentage
      @params = params
    end

    COMPARE_ATTRIBUTES = %w[id course_id points certificates completed quantile visits].freeze

    def call(enrollments)
      # We "memoize" the cleaned values used for comparison here.
      # These are re-used in the "clean" block further below, to avoid
      # re-running the expensive API serialization logic multiple times.
      @cleaned = {}

      science 'persisted-learning-evaluation' do |e|
        e.percentage = @percentage

        e.context params: @params.respond_to?(:to_unsafe_h) ? @params.to_unsafe_h : @params

        e.use { Dynamic.new.call(enrollments) }
        e.try { Persisted.new.call(enrollments) }

        # At time of comparison, the "values" are still ActiveRecord relations.
        # We cannot compare these, but need to compare the JSON generated from
        # them instead.
        #
        # We focus on a list of attributes (see +COMPARE_ATTRIBUTES+ above)
        # that are relevant for determining equality. In addition, the
        # remaining attributes would clutter up the "cleaned" data that is
        # stored for analysis.
        e.compare do |control, candidate|
          @cleaned[control] = control.decorate.as_json(api_version: 1).map {|row| row.slice(*COMPARE_ATTRIBUTES) }
          @cleaned[candidate] = candidate.decorate.as_json(api_version: 1).map {|row| row.slice(*COMPARE_ATTRIBUTES) }

          next false if @cleaned[control].count != @cleaned[candidate].count

          @cleaned[control].zip(@cleaned[candidate]).all? do |control_row, candidate_row|
            control_row == candidate_row
          end
        end

        # Ignore mismatches if everything except the "points" hashes match.
        # This is known to be the case in courses with fixed learning evaluation
        # (i.e. courses migrated from a legacy platform).
        e.ignore do |control, candidate|
          next false if @cleaned[control].count != @cleaned[candidate].count

          control = @cleaned[control].sort_by {|row| row['id'] }
          candidate = @cleaned[candidate].sort_by {|row| row['id'] }

          # Was it only a mismatch because of different order?
          next true if control == candidate

          courses_with_fixed_evaluations = Xikolo.config.persisted_learning_evaluation['legacy_courses'] || []

          # Ignore if all rows...
          control.zip(candidate).all? do |control_row, candidate_row|
            match_completely = control_row == candidate_row

            # Allowed mismatches in legacy courses (with fixed learning evaluation)
            legacy_course_mismatch = courses_with_fixed_evaluations.include?(control_row['course_id']) &&
                                     control_row['points']['percentage'] == candidate_row['points']['percentage'] &&
                                     control_row.except('points') == candidate_row.except('points')

            # A visit that has not yet been processed asynchronously in the course progress
            visits_off_by_one = control_row['visits']['total'] == candidate_row['visits']['total'] &&
                                control_row['visits']['visited'] == candidate_row['visits']['visited'] + 1 &&
                                control_row.except('visits') == candidate_row.except('visits')

            match_completely || legacy_course_mismatch || visits_off_by_one
          end
        end

        e.clean do |value|
          @cleaned[value]
        end
      end
    end
    # rubocop:enable all
  end

  class Null
    def call(enrollments)
      enrollments
    end
  end
end
end
