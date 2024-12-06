# frozen_string_literal: true

# @restful_api 1.0
#
# @property [String] name Human-readable name
# @property [String] identifier Identifier used in code
# @property [Text] description Test description
# @property [DateTime] start_date Start date of test
# @property [DateTime] end_date End date of test
# @property [Integer] max_participants Maximum number of participants
#

class UserTest < ApplicationRecord
  include Wisper::Publisher
  include SampleSizeHelper

  has_one :assignment_rule, class_name: '::AssignmentRules::AssignmentRule'
  has_many :test_groups, dependent: :destroy
  has_and_belongs_to_many :metrics, class_name: '::Metrics::Metric'
  has_many :trials
  has_and_belongs_to_many :filters

  scope :active, lambda {
    where(start_date: ...Time.now.utc).where('end_date > ?', Time.now.utc)
  }

  validates :identifier, uniqueness: true, if: :global?
  validate :no_course_overlaps, unless: :global?
  validates :name, :identifier, :start_date, :end_date,
    presence: true

  after_create :create_assignment_rule
  after_save :create_flipper_removal_job, if: :saved_change_to_end_date?

  def assign(user_id, autofinish: false, exclude_groups: [])
    return Assignment.none unless active?
    if max_participants && total_count >= max_participants
      return Assignment.none
    end
    return Assignment.none if Trial.exists?(user_id:, user_test_id: id)
    unless all_filters.all? {|filter| filter.filter user_id, course_id }
      return Assignment.none
    end
    return Assignment.none if test_groups.size == exclude_groups.size

    group = assign_to_group(exclude_groups)

    begin
      test_group = TestGroup.find_or_create_by!(user_test_id: id, index: group)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    # Add user to test group group
    Xikolo.api(:account).value!
      .rel(:memberships)
      .post(user: user_id, group: test_group.group_name)
      .value

    begin
      new_trial = test_group.trials.find_or_create_by!(
        user_id:, user_test_id: id
      )
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    new_trial.update finished: true if autofinish
    if max_participants && total_count == max_participants
      update! end_date: Time.now.utc
    end

    Assignment::ToGroup.new(test_group)
  end
  # rubocop:enable all

  def assign_to_group(excluded_groups = [])
    rule = assignment_rule
    if excluded_groups.present?
      rule = AssignmentRules::ExcludeGroupsAssignmentRule.new(rule, excluded_groups)
    end

    rule.assign(num_groups: test_groups.size)
  end

  def create_assignment_rule
    self.assignment_rule = if round_robin
                             AssignmentRules::RoundRobinAssignmentRule.create
                           else
                             AssignmentRules::RandomAssignmentRule.create
                           end
  end

  def create_flipper_removal_job
    FeatureFlipperWorker.perform_at(end_date, id)
  end

  def add_test_groups(groups)
    groups.each do |group|
      test_groups.create(
        index: test_groups.size,
        name: group[:name],
        description: group[:description].to_s,
        flippers: Array(group[:flippers])
      )
    end
  end

  def add_metrics(metrics_hash)
    metrics_hash.each do |metric_hash|
      metric_hash = {
        id: metric_hash['id'],
        type: metric_hash['type'],
        wait_interval: metric_hash['wait_interval'],
      }

      if metric_hash[:id].blank?
        metrics << Metrics::Metric.create!(metric_hash.except(:id))
      else
        m = metrics.find(metric_hash[:id])
        m.update!(metric_hash.except(:id))
      end
    end
  end

  def add_filters(filter_strings)
    filters.delete_all
    filter_strings.each do |filter|
      field_name, operator, field_value = filter.split if filter.split.size == 3
      filters << Filter.create!(
        field_name:, operator:, field_value:
      )
    end
  end

  def compute_statistics
    test_groups.find_each(&:compute_statistics)
  end

  def total_count
    trials.count
  end

  def finished_count
    trials.finished.count
  end

  def waiting_count
    return unless metrics&.any?(&:delayed?)

    map_metrics do |metric|
      trial_results.where(metric:, waiting: true).count
    end
  end

  def map_metrics
    metrics.each_with_object({}) do |metric, h|
      h[metric.id] = yield metric
    end
  end

  def trial_results
    TrialResult.for_user_test(self)
  end

  def active?
    start_date <= Time.now.utc && end_date >= Time.now.utc
  end

  def finished?
    end_date < Time.now.utc
  end

  def mean
    map_metrics do |metric|
      trial_results.where(metric:).average(:result).to_f
    end
  end

  def control
    test_groups.find_by index: 0
  end

  def treatments
    test_groups.where 'index != 0'
  end

  def all_filters
    default_filters + filters
  end

  def default_filters
    @default_filters ||= []
    # Filter.new(field_name: 'admin', operator: '==', field_value: 'false')
  end

  def to_csv(metric_name: nil)
    csv = [TrialResult.csv_headers]
    trs = trial_results.includes(:metric, trial: :test_group)
      .order(:metric_id)
    trs = trs.joins(:metric).where(metric: {name: metric_name}) if metric_name
    trs.find_each {|tr| csv += [tr.to_csv] }
    csv.join "\n"
  end

  def required_participants(effect_size: 0.5)
    sample_size(effect_size, :normal) * test_groups.count
  end

  def global?
    course_id.nil?
  end

  def context_id
    global? ? 'root' : course['context_id']
  end

  def group_prefix
    global? ? identifier : "#{identifier}.#{course['course_code']}"
  end

  def course
    @course ||= Xikolo.api(:course).value!
      .rel(:course).get(id: course_id).value!
  end

  # For course-specific user tests, other course-specific user tests are
  # allowed, but not for the same course. Global tests are also not allowed.
  def no_course_overlaps
    if UserTest.where(identifier:)
        .where(course_id: [course_id, nil])
        .where.not(id:).exists?
      errors.add :identifier, 'course_specific_test_not_allowed_for_identifier'
    end
  end

  module Assignment
    def self.none
      @none ||= Struct.new(:new?, :new_features).new(false, {})
    end

    class ToGroup
      def initialize(group)
        @group = group
      end

      def new?
        true
      end

      def new_features
        @group.flippers.index_with {|_flipper| true }
      end
    end
  end
end
