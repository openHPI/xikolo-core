# frozen_string_literal: true

module Proctoring
  ##
  # This class represents the result of an online proctoring session.
  # It contains a set of categories along with the number of violations
  # for each category during this session.
  #
  # It can be used to represent the proctoring result for a single quiz,
  # or an entire course.
  class Result
    def initialize(features, thresholds:)
      @features = features.transform_values(&:to_i)
      @thresholds = thresholds.transform_values(&:to_i)
    end

    def features
      known_keys.index_with do |key|
        @features.fetch(key, 0)
      end
    end

    # Combine the current instance's scores with <i>other_features</i> and return a new instance with the
    # accumulated scores.
    def add(other_features)
      self.class.new(
        known_keys.index_with do |key|
          @features.fetch(key, 0) + other_features.fetch(key, 0)
        end,
        thresholds: @thresholds
      )
    end

    def empty?
      @features.empty?
    end

    # Determine whether the session fulfilled all criteria.
    def perfect?
      max.zero?
    end

    def issues?
      !perfect?
    end

    # Return the highest score for any criteria. If this is greater than zero, the system discovered a violation.
    def max
      @features.values.max_by(&:to_i).to_i
    end

    # Determine whether the scores are all below the configured thresholds.
    #
    # The thresholds can define maximum values per feature/category. Only if
    # this result is truly below the threshold values for all features, the
    # entire result will be considered as below the threshold.
    #
    # Notable exception: When the threshold is 0 (zero), the value of the
    # result can be zero as well.
    def valid?
      known_keys.all? do |key|
        my_value = @features.fetch(key, 0)
        my_value.zero? || my_value < @thresholds.fetch(key, 0)
      end
    end

    # Represent the result as a JSON string.
    #
    # Example:
    #   [["nobody", 0], ["wronguser", 2]]
    def to_json(*_args)
      known_keys.map {|key| [key, @features.fetch(key, 0)] }.to_json
    end

    private

    def known_keys
      @thresholds.keys
    end
  end
end
