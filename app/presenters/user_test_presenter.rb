# frozen_string_literal: true

class UserTestPresenter < Presenter
  def_delegators :user_test, :id, :identifier, :name, :description, :start_date,
    :end_date, :waiting_count, :finished, :finished_count, :course_id,
    :total_count, :mean, :max_participants, :persisted?, :csv, :required_participants, :round_robin

  attr_accessor :user_test

  attr_reader :type, :wait_interval

  def self.create(user_test, get_dependent: false)
    new(user_test:).tap {|ut| ut.load_dependent if get_dependent }
  end

  def box_plot_data(metric_id)
    data = {groups: [], data: [], outliers: []}
    test_groups.each do |test_group|
      next if test_group.box_plot_data[metric_id].blank?

      data[:groups] << "#{test_group[:index]}#{' (Control)' if test_group.control}"
      data[:data] << test_group.box_plot_data[metric_id][0...-1]
      data[:outliers] << test_group.box_plot_data[metric_id][-1]
    end
    data.to_json
  end

  def filters_string
    filters.map {|filter| "#{filter.field_name} #{filter.operator} #{filter.field_value}" }.join(',')
  end

  def course
    return if user_test.course_id.nil?

    @course ||= Xikolo.api(:course).value!.rel(:course).get({id: user_test[:course_id]}).value!
  end

  def load_dependent
    @test_groups = user_test.rel(:test_groups).get
    @metrics = user_test.rel(:metrics).get
    @filters = user_test.rel(:filters).get
  end

  def test_groups
    @test_groups.value!
  end

  def metrics
    @metrics.value!
  end

  def filters
    @filters.value!
  end

  def active?
    Time.current.utc.between?(start_date, end_date)
  end
end
