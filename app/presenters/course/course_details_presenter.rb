# frozen_string_literal: true

class Course::CourseDetailsPresenter < CoursePresenter
  def self.build(course, enrollments, user)
    new(course:, enrollments:, user:).tap do |presenter|
      presenter.prerequisites!
      presenter.next_dates!
    end
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def prerequisites!
    return if @user.anonymous?
    return unless @course['prerequisite_status_url']

    @prereq_promise ||= Restify.new(@course['prerequisite_status_url']).get({
      user_id: @user.id,
    })
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def prerequisites
    @prerequisites ||= Course::PrerequisitesPresenter.new self, @prereq_promise&.value!
  end

  def prerequisites?
    prerequisites.try(:any?)
  end

  def next_dates!
    # This can be taken from the course context now (Restify!)
    return if @user.anonymous?

    @next_dates_promise = course_api.rel(:next_dates).get({
      course_id: @course.id,
      all: 'true',
      type: 'course_start,section_start,on_demand_expires',
      user_id: @user.id,
    }).then do |next_dates|
      next_dates[0..1].map do |next_date|
        # The course_start type would link to the course details page and we are already there.
        Course::NextDatePresenter.new(next_date, with_link: next_date['type'] != 'course_start')
      end
    end
  end

  def next_dates
    @next_dates ||= @next_dates_promise ? @next_dates_promise.value! : []
  end

  def next_dates?
    next_dates.try(:any?)
  end

  def open_mode?
    return false unless @user.anonymous?
    return false unless @user.feature?('open_mode')
    return false if @course.invite_only || @course.hidden

    previewable_items.any?
  end

  def meta_tags
    meta = {
      title: @course.title,
      description: short_description,
      keywords: meta_keywords,
      'dcterms.created' => @course.created_at,
      'dcterms.modified' => @course.updated_at,
      og: {
        # mandatory:
        title: @course.title,
        type: 'website',
        image: visual_url,
        url: Xikolo.base_url.join(course_path(@course.course_code)),
        # optional
        description: short_description,
        site_name: Xikolo.config.site_name,
        'image:secure_url' => visual_url,
        locale: @course.lang,
      },
    }

    if Xikolo.config.facebook_app_id.present?
      meta[:'fb:app_id'] = Xikolo.config.facebook_app_id
    end

    meta[:noindex] = true if @course.hidden

    meta
  end

  private

  def meta_keywords
    return if @course.classifiers.blank?

    keywords = []
    %w[keywords topic].each do |classifier|
      if @course.classifiers.key?(classifier)
        keywords += @course.classifiers[classifier]
      end
    end
    keywords.join ', '
  end

  def short_description
    return @course.abstract if @course.abstract.present?

    description_markup
  end

  def previewable_items
    @previewable_items ||= course_api
      .rel(:items)
      .get({course_id: @course.id, open_mode: true})
      .value!
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
