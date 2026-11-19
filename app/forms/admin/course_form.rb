# frozen_string_literal: true

class Admin::CourseForm < XUI::Form
  self.form_name = 'course'

  attribute :id, :uuid
  attribute :title, :single_line_string
  attribute :course_code, :single_line_string
  attribute :course_format, :single_line_string, default: 'course'
  attribute :abstract, :markup
  attribute :description, :markup,
    uploads: {purpose: 'course_course_description'}
  attribute :learning_goals, :list, subtype: :single_line_string, default: []
  attribute :alternative_teacher_text, :single_line_string
  attribute :lang, :single_line_string
  attribute :enrollment_delta, :integer, default: 0
  attribute :channel_ids, :list, subtype: :uuid, default: []
  attribute :teacher_ids, :list, subtype: :uuid, default: []

  attribute :start_date, :datetime
  attribute :display_start_date, :datetime
  attribute :end_date, :datetime
  attribute :middle_of_course_is_auto, :boolean, default: true
  attribute :middle_of_course, :datetime

  attribute :records_released, :boolean
  attribute :roa_enabled, :boolean, default: true
  attribute :roa_threshold_percentage, :integer, default: Xikolo.config.roa_threshold_percentage
  attribute :cop_enabled, :boolean, default: true
  attribute :cop_threshold_percentage, :integer, default: Xikolo.config.roa_threshold_percentage
  attribute :welcome_mail, :markup
  attribute :external_course_url, :uri

  attribute :pinboard_enabled, :boolean, default: true
  attribute :forum_is_locked, :boolean
  attribute :groups, :list, subtype: :single_line_string, default: []
  attribute :enable_video_download, :boolean
  attribute :invite_only, :boolean
  attribute :on_demand, :boolean, default: false
  attribute :published, :boolean, default: false
  attribute :placement, :list, subtype: :single_line_string, default: []
  validates :course_code, presence: true, format: /\A[\w-]+\z/
  validates :title, presence: true
  validates :lang, presence: true
  validates :description, presence: true
  validates :middle_of_course, presence: true, unless: :middle_of_course_is_auto
  validate :classifiers_format
  validate :classifiers_uniqueness

  hash_attribute :classifiers, :list,
    subtype_opts: {subtype: :single_line_string},
    keys: :cluster_keys

  validates :roa_threshold_percentage, :cop_threshold_percentage,
    numericality: {
      only_integer: true,
      greater_than: 0,
      less_than_or_equal_to: 100,
      allow_nil: true,
    }

  def self.readonly_attributes
    %w[course_code]
  end

  def to_param
    course_code
  end

  def channel_ids=(value)
    @channel_ids = Array(value).compact_blank
  end

  def clusters
    @clusters ||= CourseService::Cluster.all
  end

  def cluster_keys
    clusters.pluck(:id)
  end

  def classifiers_format
    classifiers.each do |cluster, cls|
      next if cls.all? {|c| c.match(/\A[\w\-\ ]+\z/) }

      errors.add :"classifiers_#{cluster}",
        I18n.t(:'.errors.messages.course.classifiers.invalid_format')
    end
  end

  def classifiers_uniqueness
    classifiers.each do |cluster, cls|
      next if cls.map(&:downcase).then { it.uniq.length == it.length }

      errors.add :"classifiers_#{cluster}",
        I18n.t(:'.errors.messages.course.classifiers.not_unique')
    end
  end

  class AutoMiddleDate
    def to_resource(attributes, _obj)
      # remove read-only field :middle_of_course_is_auto
      if attributes.delete('middle_of_course_is_auto') { false }
        # clear date to calculate it automatically (service-side)
        attributes['middle_of_course'] = nil
      end
      attributes
    end
  end

  process_with { AutoMiddleDate.new }

  class ChannelsToIds
    def from_resource(attributes, _obj)
      # Convert channels array to channel_ids array
      if attributes['channels'].present?
        attributes['channel_ids'] = attributes['channels'].pluck('id')
        attributes.delete('channels')
      end
      attributes
    end

    def to_resource(attributes, _obj)
      # When saving, remove channel_ids if it exists (API might not expect it)
      # The actual association update should be handled separately
      attributes
    end
  end

  process_with { ChannelsToIds.new }
end
