# frozen_string_literal: true

module CourseService
class Experiment # rubocop:disable Layout/IndentationWidth
  include Scientist::Experiment

  def initialize(name)
    @name = name
    @percentage = 0
  end

  attr_accessor :percentage

  ##
  # Determine whether the experiment should be run.
  #
  # We roll dice and run the experiment for the configured percentage of requests.
  def enabled?
    @percentage > 0 && rand(100) < @percentage
  end

  ##
  # Track the result of each experiment run.
  #
  # We are sending metadata to Telegraf, mostly focusing on whether the results
  # are matching, and how long their generation took.
  def publish(result)
    Xikolo.metrics.write(
      'scientist_experiments',
      tags: {
        name: @name,
        matched: result.matched?,
        mismatched: result.mismatched?,
        ignored: result.ignored?,
      },
      values: {
        percentage: @percentage,
        duration: [result.control, *result.candidates].sum(&:duration),
        control_duration: result.control.duration,
        candidate_duration: result.candidates.first.duration,
      }
    )

    store_mismatch_data(result) if result.mismatched?
  end

  private

  ##
  # Store information about each experiment run if results don't match.
  #
  # This allows further investigation when problems (e.g. diverging behavior)
  # surface after the experiment has run on production for a while.
  def store_mismatch_data(result)
    payload = {
      name: @name,
      context:,
      control: result.control.cleaned_value,
      candidate: result.candidates.first.cleaned_value,
      execution_order: result.observations.map(&:name),
    }

    timestamp = DateTime.now.strftime('%F-%H%I%S') # e.g. 2021-11-18-140228
    unique_identifier = SecureRandom.hex(3) # a random string of six characters

    bucket = Xikolo::S3.bucket_for(:scientist)
    bucket.put_object(
      key: "experiments/#{@name}/mismatches/#{timestamp}-#{unique_identifier}.json",
      body: payload.to_json,
      acl: 'private',
      content_type: 'application/json'
    )
  rescue Aws::S3::Errors::ServiceError => e
    ::Sentry.capture_exception(e)
    Rails.logger.error "[SCIENTIST] Could not store mismatch report in S3: #{e}"
  end
end
end
