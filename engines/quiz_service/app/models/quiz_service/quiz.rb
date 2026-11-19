# frozen_string_literal: true

module QuizService
class Quiz < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :quizzes

  has_paper_trail
  has_many :questions, dependent: :destroy
  has_many :submissions, class_name: 'QuizSubmission', dependent: :destroy
  has_many :additional_attempts, class_name: 'AdditionalQuizAttempt', dependent: :delete_all
  has_one :item, class_name: 'CourseService::Item', foreign_key: :content_id, primary_key: :id, inverse_of: :content

  EXAM_QUESTION_TYPES = %w[
    QuizService::MultipleChoiceQuestion
    QuizService::MultipleAnswerQuestion
  ].freeze

  EXAM_QUESTION_DIFFICULTIES = {
    easy: {points: 1, count: 3},
    mid: {points: 2, count: 3},
    hard: {points: 3, count: 4},
  }.freeze

  EXAM_QUESTIONS_PER_BATCH = 10

  QuestionPoolStatus = Data.define(
    :displayed_question_count,
    :pool_size,
    :difficulties,
    :question_types
  ) do
    def criteria
      [displayed_question_count, pool_size, *difficulties, question_types].compact
    end

    def valid?
      criteria.all? {|criterion| criterion[:fulfilled] }
    end
  end

  before_validation :configure_question_pool_attempts
  validate :question_pool_only_available_for_exam_quizzes

  after_commit(on: :destroy) do
    Xikolo::S3.extract_file_refs(instructions).each do |uri|
      Xikolo::S3.object(uri).delete
    end
  end

  validates :time_limit_seconds,
    :allowed_attempts,
    numericality: {only_integer: true, greater_than: 0}

  def attempt!(user_id, additional_params = {})
    with_lock do
      existing = submission_pool_for(user_id).take
      next existing if existing

      if (exam_error = exam_error_for(user_id))
        submission = submissions.build(additional_params.merge(user_id:))
        submission.errors.add(:base, exam_error)
        next submission
      end

      unless valid_question_pool?
        submission = submissions.build(additional_params.merge(user_id:))
        submission.errors.merge!(errors)
        next submission
      end

      submissions.build(
        additional_params.merge(user_id:)
      ).tap do |submission|
        if attempts_left?(user_id)
          submission.save!
          persist_question_set!(submission, user_id) if question_pool?
        else
          submission.errors.add(:base, 'no_attempts_left')
        end
      end
    end
  end

  # An exam is a question-pool quiz attached to an `exam` exercise type.
  def exam?
    question_pool? && item&.exercise_type == 'exam'
  end

  def current_quiz
    @current_quiz ||= Quiz.find(id)
  end

  def current_time_limit_seconds
    current_quiz.time_limit_seconds
  end

  def current_unlimited_time
    current_quiz.unlimited_time
  end

  def current_allowed_attempts
    current_quiz.allowed_attempts
  end

  def current_unlimited_attempts
    current_quiz.unlimited_attempts
  end

  def max_points
    questions.sum(:points)
  end

  # Pool configuration is validated explicitly when an exam starts. This lets
  # content creators build a draft pool incrementally in the editor.
  def valid_question_pool?
    errors.clear
    return true unless question_pool?

    errors_by_criterion = question_pool_status.criteria
      .reject {|criterion| criterion[:fulfilled] }
      .filter_map {|criterion| criterion[:error] }

    errors_by_criterion.each do |error|
      attribute, type, options = error
      errors.add(attribute, type, **options)
    end

    errors.empty?
  end

  def question_pool_status
    unless question_pool?
      return QuestionPoolStatus.new(nil, nil, [], nil)
    end

    displayed_question_count = displayed_question_count_criterion
    pool_size = pool_size_criterion
    difficulties = valid_displayed_question_count? ? difficulty_criteria : []
    question_types = question_types_criterion
    QuestionPoolStatus.new(displayed_question_count, pool_size, difficulties, question_types)
  end

  def avg_points
    subs = submissions.where_submitted(true)
    points = subs.joins(:quiz_submission_questions).sum(:points)
    avg_points = (points + subs.sum(:fudge_points)) / subs.size.to_f
    avg_points.nan? ? 0.0 : avg_points
  end

  def stats
    @stats ||= SubmissionStatistics.new(self)
  end

  # Whether the learner may start another attempt: within the allowed and any
  # additional attempts granted to them, and not after passing an exam.
  def attempts_left?(user_id)
    return true if unlimited_attempts
    return false if exam? && last_attempt_passed?(user_id)

    attempts = submissions.where(user_id:).where_submitted(true).count
    additional = additional_attempts.find_by(user_id:)&.count.to_i

    allowed_attempts + additional - attempts > 0
  end

  private

  def submission_pool_for(user_id)
    submissions.unsubmitted.by_user(user_id)
  end

  # Exams are locked behind a minimum course progression and are re-taken only
  # after a failed attempt. Returns an error key to reject starting a new
  # attempt, or `nil` if the attempt is allowed.
  def exam_error_for(user_id)
    return nil unless exam?
    return 'exam_locked' if item&.exam_locked_for?(user_id)
    return 'exam_passed' if last_attempt_passed?(user_id)

    nil
  end

  def last_attempt_passed?(user_id)
    submissions.where(user_id:).where_submitted(true)
      .order(quiz_submission_time: :desc).first&.passed?
  end

  # Exams (question-pool quizzes) are always time-limited and have a fixed
  # number of attempts. Both default to a sensible value but can be adjusted.
  def configure_question_pool_attempts
    return unless question_pool?

    self.unlimited_attempts = false
    self.unlimited_time = false
    self.allowed_attempts ||= 2
    self.time_limit_seconds ||= 3600
  end

  def question_pool_only_available_for_exam_quizzes
    return unless question_pool? && item && item.exercise_type != 'exam'

    errors.add(:question_pool, :only_available_for_exam_quizzes)
  end

  def valid_displayed_question_count?
    displayed_question_count.present? &&
      displayed_question_count.positive? &&
      displayed_question_count.multiple_of?(EXAM_QUESTIONS_PER_BATCH)
  end

  def displayed_question_count_criterion
    if valid_displayed_question_count?
      fulfilled_criterion(:questions_per_learner, count: displayed_question_count)
    else
      missing_criterion(:questions_per_learner_missing, :displayed_question_count, :invalid_exam_question_count)
    end
  end

  def pool_size_criterion
    unless valid_displayed_question_count?
      if displayed_question_count.present? && questions.count != displayed_question_count * 3
        error = [:questions, :invalid_exam_pool_size, {count: displayed_question_count * 3}]
      end
      return missing_criterion(:pool_size_missing_count, error:)
    end

    expected_count = displayed_question_count * 3
    difference = questions.count - expected_count
    if difference.zero?
      fulfilled_criterion(:pool_size, current_count: questions.count, required_count: expected_count)
    elsif difference.positive?
      missing_criterion(:pool_size_too_many, :questions, :invalid_exam_pool_size,
        current_count: questions.count,
        required_count: expected_count,
        count: difference)
    else
      missing_criterion(:pool_size_missing, :questions, :invalid_exam_pool_size,
        current_count: questions.count,
        required_count: expected_count,
        count: difference.abs)
    end
  end

  def difficulty_criteria
    required_question_counts_by_difficulty.map do |difficulty, required_count|
      points = EXAM_QUESTION_DIFFICULTIES.fetch(difficulty).fetch(:points)
      count = questions.where(points:).count
      if count >= required_count
        fulfilled_criterion(:difficulty, difficulty:, count:, required_count:)
      else
        missing_criterion(:difficulty, :questions, :insufficient_exam_questions_for_difficulty,
          difficulty:,
          count:,
          required_count:)
      end
    end
  end

  def question_types_criterion
    invalid_count = questions.where.not(type: EXAM_QUESTION_TYPES).count
    if invalid_count.zero?
      fulfilled_criterion(:question_types)
    else
      missing_criterion(:question_types_missing, :questions, :invalid_exam_question_type, count: invalid_count)
    end
  end

  def fulfilled_criterion(message, **options)
    {fulfilled: true, message:, options:}
  end

  def missing_criterion(message, attribute = nil, type = nil, error: nil, **options)
    error ||= [attribute, type, validation_error_options(type, options)] if attribute
    {fulfilled: false, message:, options:, error:}
  end

  def validation_error_options(type, options)
    case type
      when :invalid_exam_pool_size
        {count: options.fetch(:required_count)}
      when :insufficient_exam_questions_for_difficulty
        {
          count: options.fetch(:required_count),
          difficulty: I18n.t("items.quiz.difficulties.#{options.fetch(:difficulty)}"),
        }
      else
        {}
    end
  end

  def persist_question_set!(submission, user_id)
    question_ids = question_set_for(user_id)
    if question_ids.empty?
      question_ids = required_question_counts_by_difficulty.flat_map do |difficulty, count|
        points = EXAM_QUESTION_DIFFICULTIES.fetch(difficulty).fetch(:points)
        questions.where(points:).reorder(Arel.sql('RANDOM()')).limit(count).pluck(:id)
      end.shuffle
    end

    question_ids.each_with_index do |question_id, index|
      submission.quiz_submission_questions.create!(quiz_question_id: question_id, position: index + 1)
    end
  end

  def question_set_for(user_id)
    submissions.by_user(user_id).order(:created_at).each do |submission|
      question_ids = submission.quiz_submission_questions.order(:position, :created_at).pluck(:quiz_question_id)
      return question_ids if question_ids.any?
    end
    []
  end

  def required_question_counts_by_difficulty
    return {} unless valid_displayed_question_count?

    batches = displayed_question_count / EXAM_QUESTIONS_PER_BATCH
    EXAM_QUESTION_DIFFICULTIES.transform_values do |difficulty|
      difficulty.fetch(:count) * batches
    end
  end
end
end
