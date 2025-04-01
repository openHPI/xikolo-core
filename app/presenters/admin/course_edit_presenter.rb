# frozen_string_literal: true

class Admin::CourseEditPresenter
  extend Forwardable
  def_delegators :@form,
    :new_record?,
    :persisted?,
    :learning_goals,
    :target_groups,
    :clusters

  def_delegators :@course,
    :title,
    :course_code,
    :stage_visual_url,
    :roa_enabled?,
    :cop_enabled?

  class << self
    def for_creation(user:, form: nil)
      form ||= Admin::CourseForm.new

      presenter = new(BasicCoursePresenter.new({}), form, user)
      presenter.with_teachers! form&.teacher_ids || []
      presenter.with_statistic_dates! form.id if form&.id
      presenter
    end

    def for_course(id:, user:, form: nil)
      course = Xikolo.api(:course).value!
        .rel(:course)
        .get({id:, raw: true})
        .value!
      form ||= Admin::CourseForm.from_resource(course)

      presenter = new(BasicCoursePresenter.new(course), form, user)
      presenter.with_teachers! form&.teacher_ids || course['teacher_ids']
      presenter.with_statistic_dates! course['id']
      presenter
    end
  end

  def initialize(course, form, user)
    @channels = course_api.rel(:channels).get({per_page: 250})

    @course = course
    @form = form
    @user = user
  end

  def to_model
    @form
  end

  def channels?
    @channels.value!.any?
  end

  def channels
    @channels.value!
  end

  def course_image
    return unless visual&.image_url

    ::Course::CourseVisual.new(
      visual&.image_url,
      alt_text: course_image_filename,
      css_classes: 'course-visuals__img'
    )
  end

  def course_image_filename
    URI(visual&.image_url).path.split('/').last
  end

  def stream_info
    stream = visual&.video_stream
    return unless stream

    "#{stream.title} (#{stream.provider.name})"
  end

  def status_collection
    %w[preparation active archive].map do |status|
      [I18n.t("admin.courses.classifiers.course_status.#{status}"), status]
    end
  end

  def lang_collection
    Xikolo.config.course_languages.map do |lang|
      [I18n.t("languages.title.#{lang}"), lang]
    end
  end

  def dynamic_sortable_list(list)
    list.map do |item|
      [item, item]
    end
  end

  def access_groups_collection
    Xikolo.config.access_groups.map do |group_name, readable_name|
      [readable_name, group_name]
    end
  end

  def teachers
    @teachers.map do |teacher|
      [teacher.value['name'], teacher.value['id']]
    end
  end

  def classifier(cluster)
    value = @form.send :"classifiers_#{cluster}"
    return [] unless value

    ::Course::Classifier.where(title: value).map do |c|
      [c.localized_title, c.title]
    end
  end

  def statistic_dates?
    @statistic_dates
  end

  def statistic_dates
    @statistic_dates.value!
  end

  def proctoring_activatable?
    @user.feature?('proctoring') && Proctoring.enabled?
  end

  def course_reactivation_activatable?
    @user.feature?('course_reactivation') && CourseReactivation.enabled?
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def with_teachers!(ids)
    @teachers ||= ids.map do |teacher_id|
      # Call to_s on UUID4 to get full-length uuid (local patch would generate
      # short format which is not supported by the backend)
      course_api.rel(:teacher).get({id: teacher_id.to_s})
    end
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def with_statistic_dates!(course_id)
    @statistic_dates ||= course_api
      .rel(:stats)
      .get({course_id:, key: 'percentile_created_at_days'})
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  private

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def visual
    @visual ||= Course::Visual.find_by(course_id: @course.id)
  end
end
