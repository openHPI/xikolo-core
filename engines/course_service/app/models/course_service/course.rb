# frozen_string_literal: true

module CourseService
class Course < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :courses
  self.ignored_columns += %w[
    search_data
    auto_archive
    show_syllabus
    show_on_stage
    stage_visual_uri
    stage_statement
    policy_url
    external_registration_url
    hidden
    status
    show_on_list
    target_groups
  ]

  include ForGroups
  include CourseProviderSync

  enum :course_format, {
    course: 'course',
    workshop: 'workshop',
    project: 'project',
  }

  has_one :node, class_name: 'CourseService::Structure::Root', inverse_of: :course,
    foreign_key: :course_id, dependent: :destroy # rubocop:disable Rails/RedundantForeignKey
  has_one :visual, class_name: '::Course::Visual', dependent: :destroy

  has_many :sections, -> { order(:position) }, inverse_of: :course
  has_many :items, through: :sections

  has_many :channels_courses,
    class_name: 'CourseService::ChannelsCourse',
    dependent: :destroy

  has_many :channels, through: :channels_courses
  has_many :classifier_assignments, dependent: :delete_all
  has_many :classifiers, through: :classifier_assignments

  has_many :content_tests
  has_many :metadata,
    class_name: 'CourseService::Metadata',
    dependent: :destroy
  has_many :offers, class_name: '::Course::Offer', dependent: :destroy

  has_many :shorts, class_name: 'CourseService::Short', dependent: :destroy

  scope :published_courses, -> { where(published: true, deleted: false) }
  scope :unrestricted, -> { published_courses.where(groups: []) }
  # Mirrors `Course#status`: a course is active when it has no start date and
  # its end date has not passed yet (or no timebox at all), or when the start
  # date is in the past and the end date in the future.
  scope :active, lambda {
    now = Time.zone.now
    base = where(published: true, deleted: false)

    [
      base.where(start_date: nil, end_date: nil),      # no start, no end -> active
      base.where(start_date: nil, end_date: now..),    # no start, ends in the future -> active
      base.where(start_date: ...now, end_date: now..), # started in the past, still running -> active
    ].reduce(:or)
  }
  scope :in_preparation, -> { where(published: false) }
  scope :upcoming,       -> { where(published: true, deleted: false, start_date: Time.zone.now..) }
  scope :ended_by, ->(time) { where(end_date: ..time) }
  scope :self_paced, lambda {
    now = Time.zone.now
    base = where(published: true, deleted: false)
    [
      base.ended_by(now), # timebox has passed
      base.where(start_date: ...now).where(end_date: nil), # started, never ends
    ].reduce(:or)
  }
  scope :not_deleted, -> { where(deleted: false) }
  scope :deleted_for_purge, lambda {|before = 6.months.ago|
    where(deleted: true, deleted_at: ..before).order(:id)
  }
  scope :visible,        -> { where.not(placement: []) }
  # In Rails 6, these could use begin-/end-less ranges
  scope :started,        -> { where(courses: {start_date: ...Time.now.utc}) }
  scope :not_started,    -> { where(start_date: nil).or(where('start_date > ?', Time.current)) }
  scope :not_ended,      -> { where('courses.end_date > ?', Time.now.utc) }
  scope :ended,          -> { where(end_date: ...Time.current) }
  scope :current,        -> { active.started.not_ended }
  scope :by_classifier, lambda {|classifier_id|
    where('hstore(\'id\', ?) <@ ANY(fixed_classifiers)', classifier_id)
  }

  has_many :enrollments, dependent: :restrict_with_exception
  has_many :certificate_records,
    class_name: '::Certificate::Record',
    dependent: :destroy
  has_many :certificate_templates,
    class_name: '::Certificate::Template',
    dependent: :destroy

  PLACEMENTS = %w[Open4All Archive].freeze

  validate :placement_values_are_allowed
  validate :placement_has_no_duplicates

  validates :title, :description, presence: true

  validate :start_date_before_end_date

  validates :course_code,
    presence: true,
    format: /\A[\w-]+\z/,
    uniqueness: {case_sensitive: false}

  validates :cop_threshold_percentage, :roa_threshold_percentage,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 100,
    }

  def update_search_index
    query = <<~SQL.squish
      UPDATE courses SET
      search_data =
        coalesce(title::text, '') || ' ' ||
        coalesce(course_code::text, '') || ' ' ||
        coalesce(abstract, '') || ' ' ||
        coalesce(description, '') || ' ' ||
        coalesce(alternative_teacher_text::text, '') || ' ' ||
        coalesce(
          (SELECT
            string_agg(name, ' ')
            FROM teachers WHERE teachers.id = ANY(courses.teacher_ids)),
          ''
        ) || ' ' ||
        coalesce(
          (SELECT
            string_agg(classifiers.title, ' ')
            FROM classifiers_courses
            INNER JOIN classifiers ON classifiers_courses.classifier_id = classifiers.id
            WHERE classifiers_courses.course_id = courses.id),
          ''
        )
      WHERE id = '#{id}'
    SQL
    self.class.connection.update(query, 'update course search index', [])
  end

  after_save :update_enrollments

  after_commit(on: :create) do
    NextDate::CourseStartSyncJob.perform_later(id)
    UpdateCourseSearchIndexJob.perform_later(id)
  end

  after_commit(on: :update) do
    NextDate::CourseStartSyncJob.perform_later(id)
    UpdateCourseSearchIndexJob.perform_later(id)
    sections.pluck(:id).each do |section_id|
      NextDate::SectionStartSyncJob.perform_later(section_id)
    end
    items.pluck(:id).each do |item_id|
      NextDate::ItemSubmissionDeadlineSyncJob.perform_later(item_id)
      NextDate::ItemSubmissionPublishingSyncJob.perform_later(item_id)
    end
    ::PinboardService::SearchCourseUpdateJob.perform_later(decorate.as_event)
  end

  class << self
    def by_identifier(param)
      if (uuid = UUID4.try_convert(param))
        where('lower(course_code) = lower(?) OR id = ?', param, uuid.to_s)
      else
        where('lower(course_code) = lower(?)', param)
      end
    end

    def autocomplete(term)
      term = sanitize_sql_like(term.to_s)
      search_title = arel_table[:title].matches("%#{term}%")
      search_course_code = arel_table[:course_code].matches("%#{term}%")
      where(search_title.or(search_course_code))
    end

    # This search scope is used in Catalog::Course#search_by_text in xi-web.
    # Any change there must be reflected here below too.
    def search_by_text(query)
      query.split.reduce(all) do |memo, term|
        term = sanitize_sql_like(term)
        memo.where('search_data ILIKE ?', "%#{term}%")
      end
    end
  end

  def to_param
    course_code
  end

  def select_title
    "#{course_code} - #{title}"
  end

  def started?
    start_date.nil? || start_date.past?
  end

  def published?
    published
  end

  def status
    return 'external' if external_course_url.present?
    return 'preparation' unless published?

    now = Time.zone.now
    if start_date.nil?
      # No start date → self-paced if end passed, else active
      return 'self-paced' if end_date && now > end_date

      'active'
    elsif now < start_date
      # Start date in the future → upcoming
      'upcoming'
    elsif end_date.nil? || now > end_date
      # Start in the past + no end, or end passed → self-paced
      'self-paced'
    else
      # Start in the past + end in the future → active
      'active'
    end
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

  def classifiers=(classifiers)
    return if classifiers.nil?

    case classifiers
      when Hash
        super(classifiers.compact.map do |cluster, values|
          cluster = Cluster.find(cluster)
          values.map.with_index(1) do |value, i|
            cluster.classifiers
              .create_with(translations: {Xikolo.config.locales['default'] => value}, position: i)
              .find_or_create_by!(title: value)
          rescue ActiveRecord::RecordNotUnique
            retry
          end
        end.flatten)
      when Classifier
        super([classifiers])
      else
        super
    end
  end

  def hidden?
    placement.blank?
  end

  # Whether any user can enroll in this course
  def enrollable?
    !invite_only && external_course_url.blank?
  end

  def archived?
    status == 'self-paced'
  end

  def public?
    published? &&
      !hidden? &&
      groups.empty?
  end

  def goals
    @goals ||= CourseGoals.new(self)
  end

  def displayed_start_date
    display_start_date.nil? ? start_date : display_start_date
  end

  def confirmation_of_participation?(enrollment)
    return false unless records_released?
    return false unless cop_enabled?

    enrollment.visits_percentage >= cop_threshold_percentage
      || !!record_of_achievement?(enrollment)
  end

  def record_of_achievement?(enrollment)
    return false unless records_released?
    return false unless roa_enabled?
    return exam_passed?(enrollment) if exam?

    enrollment.points_percentage >= roa_threshold_percentage
  end

  # Does this course have an exam (a quiz item with the `exam` exercise type)?
  # A course can have at most one exam.
  def exam?
    exam.present?
  end

  # The course's exam item (a published quiz with the `exam` exercise type),
  # if any. A course can have at most one exam.
  def exam
    @exam ||= items.published.exams.includes(:content).first
  end

  # The passing threshold of the course's exam quiz, if any.
  def exam_pass_percentage
    exam&.content&.pass_percentage
  end

  # Has the learner passed the course's exam, i.e. does their most recent
  # submitted exam attempt reach the quiz's passing threshold?
  def exam_passed?(enrollment)
    return false if enrollment.nil? || enrollment.user_id.blank?

    quiz = exam&.content
    return false if quiz.nil?

    quiz.submissions
      .where(user_id: enrollment.user_id)
      .where.not(quiz_submission_time: nil)
      .order(quiz_submission_time: :desc).first&.passed? || false
  end

  def cop_threshold_percentage
    self[:cop_threshold_percentage] || Xikolo.config.cop_threshold_percentage
  end

  def roa_threshold_percentage
    self[:roa_threshold_percentage] || Xikolo.config.roa_threshold_percentage
  end

  # Certificates are no longer issued. Only records that were already issued
  # (previously for proctored tests) remain available.
  def certificate?(enrollment)
    return false unless records_released?

    return enrollment.certificate_issued if enrollment.respond_to?(:certificate_issued)

    certificate_records.exists?(
      user_id: enrollment.user_id,
      type: ::Certificate::Record::CERT
    )
  end

  def allows_reactivation?
    on_demand && status == 'self-paced'
  end

  def ended?
    return false if runs_forever?

    status == 'self-paced' && !on_demand
  end

  def runs_forever?
    return false if end_date

    # There can be courses without end_date, but past submission
    # deadlines in graded assignments. Those are not running
    # forever in terms of "RoA is available forever".
    # Therefore we check the availability of graded assignments
    # without submission deadline.
    graded_assignments_forever?
  end

  def graded_assignments_forever?
    items.where(
      content_type: 'quiz',
      exercise_type: 'main',
      submission_deadline: nil
    ).any?
  end

  def middle_of_course_is_auto?
    self[:middle_of_course].nil?
  end

  # this is used for statistics, so it might be auto or custom set
  def middle_of_course
    if self[:middle_of_course].nil? && start_date.present? && end_date.present?
      start_date + ((end_date - start_date) / 2)
    else
      self[:middle_of_course]
    end
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

    teachers_by_id = CourseService::Teacher.where(id: teacher_ids).index_by(&:id)
    teacher_ids.filter_map {|id| teachers_by_id[id]&.name }.join(', ')
  end

  def skills(version: CourseService::Metadata::VERSION)
    metadata.find_by(name: CourseService::Metadata::TYPE::SKILLS, version:)
  end

  def educational_alignment(version: CourseService::Metadata::VERSION)
    metadata.find_by(name: CourseService::Metadata::TYPE::EDUCATIONAL_ALIGNMENT, version:)
  end

  def license(version: CourseService::Metadata::VERSION)
    metadata.find_by(name: CourseService::Metadata::TYPE::LICENSE, version:)
  end

  def stats
    @stats ||= ::Course::Statistics.new(self)
  end

  def students_group_name
    "course.#{course_code}.students"
  end

  def alternative_teacher_text=(value)
    super(value&.strip&.empty? ? nil : value)
  end

  # rubocop:disable-next Rails/SkipsModelValidations
  def mark_for_recalculation!
    if legacy?
      update_attribute(:progress_stale_at, Time.current)
    else
      node.update_attribute(:progress_stale_at, Time.current)
    end
  end

  def mark_recalculated!
    update_attribute(:progress_calculated_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
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

  ##
  # "Legacy" courses are those without a course content tree.
  # Sorting and hierarchy is determined from attributes on items and sections,
  # not from structure nodes.
  #
  # @deprecated
  def legacy?
    node.blank?
  end

  private

  def start_date_before_end_date
    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      errors.add(:start_date, 'The start date cannot be later than the end date.')
    end
  end

  def update_enrollments
    return unless deleted

    # rubocop:disable-next Rails/SkipsModelValidations
    enrollments.update_all deleted: true
  end

  def placement_values_are_allowed
    return if placement.is_a?(Array) && (placement - PLACEMENTS).empty?

    errors.add(:placement, 'contains invalid values')
  end

  def placement_has_no_duplicates
    return if placement.blank?

    errors.add(:placement, 'contains duplicate values') if placement.uniq.length != placement.length
  end
end
  # rubocop:enable all
end
