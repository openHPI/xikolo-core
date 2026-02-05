# frozen_string_literal: true

module Course
  class Course < ::ApplicationRecord
    self.ignored_columns += %w[search_data channel_id]

    has_one :node,
      class_name: '::Course::Structure::Root',
      inverse_of: :course,
      foreign_key: :course_id, # rubocop:disable Rails/RedundantForeignKey
      dependent: :destroy
    has_one :visual,
      class_name: '::Course::Visual',
      dependent: :destroy
    has_many :sections, inverse_of: :course # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :items, through: :sections
    has_many :content_tests # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :enrollments, dependent: :restrict_with_exception
    has_many :certificate_records,
      class_name: '::Certificate::Record',
      dependent: :destroy
    has_many :certificate_templates,
      class_name: '::Certificate::Template',
      dependent: :destroy
    has_many :classifier_assignments,
      class_name: '::Course::ClassifierAssignment',
      dependent: :delete_all
    has_many :classifiers, through: :classifier_assignments
    has_many :metadata,
      class_name: '::Course::Metadata',
      dependent: :destroy
    has_many :offers, class_name: '::Course::Offer', dependent: :destroy
    has_many :channels_courses,
      class_name: 'Course::ChannelsCourse',
      dependent: :destroy

    has_many :channels, through: :channels_courses

    class << self
      def by_identifier(param)
        if (uuid = UUID4.try_convert(param))
          where('lower(course_code) = lower(?) OR id = ?', param, uuid.to_s)
        else
          where('lower(course_code) = lower(?)', param)
        end
      end

      def not_deleted
        where(deleted: false)
      end
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Course instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Course')
    end

    def to_param
      course_code
    end

    def select_title
      "#{course_code} - #{title}"
    end

    ##
    # "Legacy" courses are those without a course content tree.
    # Sorting and hierarchy is determined from attributes on items and sections,
    # not from structure nodes.
    #
    # @deprecated
    def legacy?
      node.blank?
    end

    def needs_recalculation?
      if legacy?
        return true if progress_calculated_at.nil?
        return false if progress_stale_at.nil?

        progress_stale_at > progress_calculated_at
      else
        node.needs_recalculation?
      end
    end

    def recalculation_allowed?
      return true if progress_calculated_at.blank?

      progress_calculated_at < 1.hour.ago
    end

    def started?
      start_date.nil? || start_date.past?
    end

    def published?
      %w[active archive].include? self[:status]
    end

    ##
    # Has the course content ever been unlocked?
    #
    def was_available?
      published? && started?
    end

    def offers_reactivation?
      on_demand
    end

    ##
    # The current de-facto course status.
    # Courses that are marked to be archived automatically are considered
    # to be active after the end date has passed.
    #
    def status
      if end_date&.past? && auto_archive && self[:status] == 'active'
        'archive'
      else
        self[:status]
      end
    end

    def middle_of_course
      if self[:middle_of_course].nil? && start_date.present? && end_date.present?
        start_date + ((end_date - start_date) / 2)
      else
        self[:middle_of_course]
      end
    end

    def stage_visual_url
      Xikolo::S3.object(stage_visual_uri).public_url if stage_visual_uri?
    end

    def subtitle_offer
      items.where(content_type: 'video').then do |items|
        ::Video::Video.includes(:subtitles)
          .where(id: items.pluck(:content_id))
          .pluck(:lang)
      end.compact.flatten.uniq
    end

    def teacher_text
      return alternative_teacher_text if alternative_teacher_text.present?

      Teacher.where(id: teacher_ids).pluck(:name).join(', ')
    end

    def skills(version: ::Course::Metadata::VERSION)
      metadata.find_by(name: ::Course::Metadata::TYPE::SKILLS, version:)
    end

    def educational_alignment(version: ::Course::Metadata::VERSION)
      metadata.find_by(name: ::Course::Metadata::TYPE::EDUCATIONAL_ALIGNMENT, version:)
    end

    def license(version: ::Course::Metadata::VERSION)
      metadata.find_by(name: ::Course::Metadata::TYPE::LICENSE, version:)
    end

    def stats
      @stats ||= ::Course::Statistics.new(self)
    end
  end
end
