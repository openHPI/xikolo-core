# frozen_string_literal: true

# @restful_api 1.0
#
# @property [Float] ratio Percentage for this group
# @property [Integer] index Group index
# @property [UUID] user_test_id UserTest ID
#

class TestGroup < ApplicationRecord
  include SampleSizeHelper
  include TestHelper
  include Wisper::Publisher

  belongs_to :user_test
  has_many :trials, dependent: :destroy

  validates :index, uniqueness: {scope: :user_test_id}
  validates :flippers, uniqueness: {scope: :user_test_id}
  validate :valid_flipper_values

  serialize :waiting_count, Hash
  serialize :mean, Hash
  serialize :change, Hash
  serialize :confidence, Hash
  serialize :effect, Hash
  serialize :required_participants, Hash
  serialize :box_plot_data, Hash

  default_scope { order('index ASC') }

  after_create {|test_group| publish(:test_group_created, test_group) }

  delegate :finished?, to: :user_test

  def group_name
    @group_name ||= "grouping.#{user_test.group_prefix}.#{index}"
  end

  def persist_flippers(value)
    # Passing in `nil` as value will advise the Feature::Update operation in
    # xi-account to destroy the corresponding flipper.
    flippers_for_account = flippers.index_with {|_flipper| value }

    Xikolo.api(:account).value!
      .rel(:group)
      .get(id: group_name)
      .value
      .rel(:flippers)
      .patch(flippers_for_account, context: user_test.context_id)
      .value
  end

  def total_count
    trials.size
  end

  def finished_count
    trials.finished.size
  end

  def control?
    index.zero?
  end

  def metric_mean(metric)
    trial_results(metric).average :result
  end

  def results(metric = nil)
    return trial_results(metric).with_result.pluck :result if metric

    map_metrics do |m|
      trial_results(m).with_result.pluck :result
    end
  end

  def compute_statistics(metric = nil)
    TestGroup.transaction do
      compute_waiting_count metric
      compute_mean metric
      compute_change metric
      compute_confidence metric
      compute_effect metric
      compute_required_participants metric
      compute_box_plot_data metric
      save!
    end
  end

  def compute_waiting_count(metric = nil)
    if metric
      waiting_count[metric.id] = metric_waiting_count metric
    else
      self.waiting_count = map_metrics {|m| metric_waiting_count(m) }
    end
  end

  private

  def valid_flipper_values
    errors.add(:flippers, :blank) if flippers.nil? || flippers.any?(&:blank?)
  end

  def skip_tests?
    control? || finished_count.zero? ||
      user_test.control.finished_count.zero?
  end

  def map_metrics
    user_test.reload.metrics.each_with_object({}) do |metric, h|
      h[metric.id] = yield metric
    end
  end

  def metric_waiting_count(metric)
    trial_results(metric).waiting.size if metric.delayed?
  end

  def compute_mean(metric = nil)
    if metric
      mean[metric.id] = metric_mean(metric)
    else
      self.mean = map_metrics {|m| metric_mean(m) }
    end
  end

  def trial_results(metric = nil)
    results = TrialResult.for_test_group(self)
    results.where! metric: metric if metric
  end

  def compute_change(metric = nil)
    if skip_tests?
      self.change = {}
      return
    end
    if metric
      change[metric.id] = metric_change metric
    else
      self.change = map_metrics {|m| metric_change m }
    end
  end

  def metric_change(metric)
    if metric_mean(metric).nil? || user_test.control.metric_mean(metric).nil?
      return
    end

    control_mean = user_test.control.metric_mean(metric)
    (metric_mean(metric) - control_mean) / control_mean
  end

  def compute_confidence(metric = nil)
    if skip_tests? || !finished?
      self.confidence = {}
    elsif metric
      confidence[metric.id] = metric_confidence metric
    else
      self.confidence = map_metrics {|m| metric_confidence m }
    end
  end

  def metric_confidence(metric)
    p_value = run_t_test(metric)
    p_value.nil? ? nil : 1 - p_value
  end

  def run_t_test(metric)
    return if skip_tests?

    control = user_test.control.results metric
    treatment = results metric
    return if control.empty? || treatment.empty?

    two_sample_t(control, treatment)[:p_value]
  end

  def compute_effect(metric = nil)
    if skip_tests?
      self.effect = {}
    elsif metric
      effect[metric.id] = metric_effect(metric)
    else
      self.effect = map_metrics {|m| metric_effect(m) }
    end
  end

  def metric_effect(metric)
    control = user_test.control.results metric
    treatment = results metric
    return if control.empty? || treatment.empty?

    effect_size control, treatment, type: metric.distribution
  end

  def compute_required_participants(metric = nil)
    if skip_tests?
      self.required_participants = {}
    elsif metric
      required_participants[metric.id] = metric_required_participants metric
    else
      self.required_participants = map_metrics do |m|
        metric_required_participants m
      end
    end
  end

  def metric_required_participants(metric)
    control = user_test.control.results metric
    treatment = results metric
    return if control.empty? || treatment.empty?

    sample_size(effect_size(control, treatment, type: metric.distribution),
      metric.distribution)
  end

  def compute_box_plot_data(metric = nil)
    if metric
      box_plot_data[metric.id] = metric_box_plot_data metric
    else
      self.box_plot_data = map_metrics {|m| metric_box_plot_data m }
    end
  end

  def metric_box_plot_data(metric)
    results_ = results metric
    return if metric.distribution == 'binomial'
    return [0, 0, 0, 0, 0, []] if results_.empty?

    # TODO: Run once after finish
    q1 = DescriptiveStatistics.percentile(25, results_)
    median = DescriptiveStatistics.median(results_)
    q3 = DescriptiveStatistics.percentile(75, results_)
    iqr = q3 - q1

    lower_whisker = median - (1.5 * iqr)
    higher_whisker = median + (1.5 * iqr)

    low = results_.select {|x| x >= lower_whisker }.min
    high = results_.select {|x| x <= higher_whisker }.max
    outlier = results_.select {|x| x > higher_whisker || x < lower_whisker }
    [low, q1, median, q3, high, outlier]
  end
end
