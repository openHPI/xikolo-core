# frozen_string_literal: true

class Course < ApplicationRecord
  include ForGroups
  include CourseProviderSync

  has_one :node, class_name: '::Structure::Root', foreign_key: :course_id, dependent: :destroy # rubocop:disable Rails/RedundantForeignKey
  has_one :visual, class_name: '::Duplicated::Visual', dependent: :destroy

  has_many :sections, -> { order('position ASC') }, inverse_of: :course
  has_many :items, through: :sections
  belongs_to :channel, optional: true
  has_and_belongs_to_many :classifiers
  has_and_belongs_to_many :documents

  has_many :course_set_entries, dependent: :destroy
  has_many :course_sets,
    through: :course_set_entries
  has_many :related_sets,
    through: :course_sets,
    source: :linked_sets,
    class_name: 'CourseSet'
  has_many :relations,
    through: :course_sets,
    source: :course_set_relations,
    class_name: 'Relation'
  has_many :content_tests
  has_many :offers, class_name: '::Duplicated::Offer', dependent: :destroy

  default_scope { order('courses.start_date DESC') }
  scope :published, lambda {
    where(deleted: false, status: %w[active archive])
  }
  scope :unrestricted,   -> { published.where(groups: []) }
  scope :active,         -> { where(status: 'active') }
  scope :not_deleted,    -> { where(deleted: false) }
  # In Rails 6, these could use begin-/end-less ranges
  scope :started,        -> { where(courses: {start_date: ...Time.now.utc}) }
  scope :not_ended,      -> { where('courses.end_date > ?', Time.now.utc) }
  scope :current,        -> { active.started.not_ended }
  scope :by_classifier, lambda {|classifier_id|
    where('hstore(\'id\', ?) <@ ANY(fixed_classifiers)', classifier_id)
  }
  scope :for_user, lambda {|current_user|
    if current_user.allowed? 'course.course.index'
      self
    else
      enrolled_courses = if current_user.anonymous?
                           Enrollment.none
                         else
                           Enrollment.active.where(user_id: current_user.id)
                         end.select(:course_id)

      [
        where(id: enrolled_courses),
        published.where(hidden: false).for_groups(user: current_user.id),
      ].reduce(:or)
    end
  }

  has_many :enrollments, dependent: :restrict_with_exception

  STATES = %w[preparation active archive].freeze

  validates :title, :status, :description, presence: true

  validates :status, inclusion: {
    in: STATES,
    message: '%{value} is not a valid course state',
  }

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

  def stage_visual_url
    Xikolo::S3.object(stage_visual_uri).public_url if stage_visual_uri?
  end

  after_save :update_enrollments

  after_commit(on: :create) do
    NextDate::CourseStartSyncWorker.perform_async(id)
    UpdateCourseSearchIndexWorker.perform_async(id)
    Msgr.publish(decorate.as_event, to: 'xikolo.course.course.create')
  end

  after_commit(on: :update) do
    NextDate::CourseStartSyncWorker.perform_async(id)
    UpdateCourseSearchIndexWorker.perform_async(id)
    sections.pluck(:id).each do |section_id|
      NextDate::SectionStartSyncWorker.perform_async(section_id)
    end
    items.unscope(:order).pluck(:id).each do |item_id|
      NextDate::ItemSubmissionDeadlineSyncWorker.perform_async(item_id)
      NextDate::ItemSubmissionPublishingSyncWorker.perform_async(item_id)
    end
    Msgr.publish(decorate.as_event, to: 'xikolo.course.course.update')

    if previous_changes['deleted'] == [false, true]
      Msgr.publish(decorate.as_event, to: 'xikolo.course.course.destroy')
    end

    if record_conditions_changed?
      EnrollmentCompletionWorker.perform_async(id)
    end
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

  def status
    if end_date.present? && end_date < Time.zone.now \
      && auto_archive && self[:status] == 'active'
      'archive'
    else
      self[:status]
    end
  end

  def state
    now = Time.zone.now
    if external_course_url.present?
      'external'
    elsif self[:status] == 'preparation'
      'preparation'
    elsif start_date && now < start_date
      'announced'
    elsif display_start_date && now < display_start_date
      'preview'
    elsif end_date && now < end_date
      'active'
    else
      'self-paced'
    end
  end

  def accessible?
    start_date ? start_date.past? : false
  end

  # Whether any user can enroll in this course
  def enrollable?
    !invite_only && external_course_url.blank?
  end

  def archived?
    status == 'archive'
  end

  def public?
    self[:status] != 'preparation' &&
      !hidden &&
      groups.empty?
  end

  def prerequisites
    @prerequisites ||= Prerequisites.new(self)
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

    enrollment.visits_percentage >= cop_threshold_percentage \
      || !!record_of_achievement?(enrollment)
  end

  def record_of_achievement?(enrollment)
    return false unless records_released?
    return false unless roa_enabled?

    enrollment.points_percentage >= roa_threshold_percentage
  end

  def cop_threshold_percentage
    self[:cop_threshold_percentage] || Xikolo.config.cop_threshold_percentage
  end

  def roa_threshold_percentage
    self[:roa_threshold_percentage] || Xikolo.config.roa_threshold_percentage
  end

  def certificate?(enrollment)
    return false unless records_released?

    enrollment.proctored? && record_of_achievement?(enrollment)
  end

  def transcript_of_records?(enrollment)
    return false unless records_released?
    return false if relations.blank?

    Prerequisites.new(self).status_for(enrollment.user_id).fulfilled?
  end

  def allows_reactivation?
    on_demand && state == 'self-paced'
  end

  def ended?
    return false if runs_forever?

    state == 'self-paced' && !on_demand
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

  def students_group_name
    "course.#{course_code}.students"
  end

  def alternative_teacher_text=(value)
    super(value&.strip&.empty? ? nil : value)
  end

  # rubocop:disable Rails/SkipsModelValidations
  def mark_for_recalculation!
    if legacy?
      update_attribute(:progress_stale_at, Time.current)
    else
      node.update_attribute(:progress_stale_at, Time.current)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

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

  def update_enrollments
    return unless deleted

    # rubocop:disable Rails/SkipsModelValidations
    enrollments.update_all deleted: true
    # rubocop:enable Rails/SkipsModelValidations
  end

  def record_conditions_changed?
    # Are records to be released right now?
    return true if previous_changes['records_released'] == [false, true]

    # No changes needed if records have not been released yet.
    return false unless records_released?

    # Finally, check if any threshold for the different certificate types
    # has been changed.
    %w[roa_threshold_percentage cop_threshold_percentage].any? do |k|
      previous_changes.key? k
    end
  end
end
# rubocop:enable all
