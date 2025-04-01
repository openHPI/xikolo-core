# frozen_string_literal: true

class Admin::UserTestForm < XUI::Form
  self.form_name = 'user_test'

  class TestGroup < XUI::Form
    self.form_name = 'test_group'

    attribute :name, :single_line_string
    attribute :description, :text
    attribute :flippers_string, :single_line_string

    validates :name, presence: true

    class FlippersArray
      def to_resource(resource, _obj)
        resource['flippers'] = resource.delete('flippers_string').to_s.split(',').map(&:strip)
        resource
      end

      def from_resource(resource, _obj)
        if (flippers = resource.delete('flippers'))
          resource['flippers_string'] = flippers.join(', ')
        end
        resource
      end
    end

    process_with { FlippersArray.new }
  end

  class Metric < XUI::Form
    self.form_name = 'metric'

    attribute :id, :uuid
    attribute :type, :single_line_string
    attribute :wait_interval, :integer

    validates :type, presence: true
    validates :wait_interval, presence: true
  end

  attribute :id, :uuid
  attribute :name, :single_line_string
  attribute :description, :text
  attribute :identifier, :single_line_string
  attribute :course_id, :uuid
  attribute :round_robin, :boolean, default: false
  attribute :start_date, :datetime
  attribute :end_date, :datetime
  attribute :max_participants, :integer
  attribute :metrics, :list, subtype: :subform, subtype_opts: {klass: Metric}, default: []
  attribute :filter_string, :single_line_string
  attribute :test_groups, :list, subtype: :subform, subtype_opts: {klass: TestGroup}, default: []

  validates :name, presence: true
  validates :description, presence: true
  validates :identifier, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :test_groups, presence: true

  def self.readonly_attributes
    %w[identifier course_id]
  end

  def initialize(*)
    super

    @metrics_promise = Xikolo.api(:grouping).value!.rel(:metrics).get({available: true})
    @courses_promise = Xikolo.api(:course).value!.rel(:courses).get({groups: 'any', per_page: 250})
  end

  class FilterString
    def to_resource(resource, _obj)
      resource['filter_strings'] = resource.delete('filter_string').to_s.split(',').map(&:strip)
      resource
    end

    def from_resource(resource, _obj)
      if (filters = resource.delete('filters'))
        resource['filter_string'] = filters.map do |filter|
          "#{filter.field_name} #{filter.operator} #{filter.field_value}"
        end.join(', ')
      end
      resource
    end
  end

  process_with { FilterString.new }

  def all_metrics
    @metrics_promise.value!
  end

  def all_courses
    @courses_promise.value!
  end

  def new_metric
    Metric.new
  end

  def new_test_group
    TestGroup.new
  end

  def save
    return unless valid?

    if persisted?
      grouping_api.rel(:user_test).patch(to_resource, params: {id: id.to_s}).value!
    else
      grouping_api.rel(:user_tests).post(to_resource).value!
    end
  rescue Restify::BadRequest => e
    remote_errors e.errors
  end

  private

  def grouping_api
    @grouping_api ||= Xikolo.api(:grouping).value!
  end
end
