# frozen_string_literal: true

class Admin::CourseForm < XUI::Form
  extend ChannelHelper

  self.form_name = 'course'

  attribute :id, :uuid
  attribute :title, :single_line_string
  attribute :course_code, :single_line_string
  attribute :abstract, :markup
  attribute :description, :markup,
    uploads: {purpose: 'course_course_description'}
  attribute :target_groups, :list, subtype: :single_line_string, default: []
  attribute :learning_goals, :list, subtype: :single_line_string, default: []
  attribute :alternative_teacher_text, :single_line_string
  attribute :status, :single_line_string, default: 'preparation'
  attribute :lang, :single_line_string
  attribute :enrollment_delta, :integer, default: 0
  attribute :channel_id, :uuid
  attribute :show_on_stage, :boolean, default: false
  attribute :stage_statement, :markup
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

  attribute :has_collab_space, :boolean, default: true
  attribute :pinboard_enabled, :boolean, default: true
  attribute :forum_is_locked, :boolean
  attribute :groups, :list, subtype: :single_line_string, default: []
  attribute :enable_video_download, :boolean
  attribute :hidden, :boolean
  attribute :show_on_list, :boolean, default: true
  attribute :invite_only, :boolean
  localized_attribute :external_registration_url, :uri
  attribute :show_syllabus, :boolean, default: true
  attribute :auto_archive, :boolean, default: true
  attribute :on_demand, :boolean, default: false
  attribute :proctored, :boolean, default: false
  localized_attribute :policy_url, :uri

  attribute :rating_stars, :float
  attribute :rating_votes, :integer

  attribute :stage_visual_upload_id, :upload,
    purpose: :course_course_stage_visual,
    image_width: stage_min_width,
    image_height: stage_min_height

  STATES = %w[preparation active archive].freeze

  validates :status, presence: true, inclusion: {in: STATES, message: I18n.t(:'.errors.messages.course.status.invalid')}
  validates :course_code, presence: true, format: /\A[\w\-]+\z/
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

  def clusters
    @clusters ||= Course::Cluster.all
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
      next if cls.map(&:downcase).then { _1.uniq.length == _1.length }

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
end
