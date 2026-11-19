# frozen_string_literal: true

class Course::CourseDetailsPresenter < CoursePresenter
  def self.build(course, enrollments, user)
    new(course:, enrollments:, user:)
  end

  def teaser_player
    video = visual&.video
    return unless video&.pip_stream

    @teaser_player ||= if Video::BunnyPlayer.compatible?(video)
                         Video::BunnyPlayer.build(
                           video:, course: @course,
                           signed_url_path: teaser_signed_url_course_path(course_code),
                           poster: visual.image_url,
                           user: @user
                         )
                       else
                         VideoPresenter.new(video:, user: @user, course: @course).player
                       end
  end

  def mark_completed?
    return false unless enrolled? && !enrollment.completed?

    Catalog::Course.released.active_for(@user, [enrollment]).exists?
  end

  def enrollment_count
    return if external?

    count = @course.stats.enrollments.current
    count if count >= 500 || @user.allowed?('course.enrollment_counter.view')
  end

  # Whether the user may enter the course content (e.g. resume the course).
  def access_allowed?
    # Users who may preview content (e.g. teachers) can always enter.
    return true if @user.allowed? 'course.content.access'
    return false if @user.anonymous?

    # Learners can enter once the course has started. External courses are taken elsewhere.
    @course.was_available? && @course.external_course_url.blank?
  end

  def open_mode?
    return false unless @user.anonymous?
    return false unless @user.feature?('open_mode')
    return false if @course.invite_only || @course.hidden?

    previewable_items.any?
  end

  def meta_tags
    og_image = og_image_url

    meta = {
      title: @course.title,
      description: short_description&.truncate(150),
      keywords: meta_keywords,
      'dcterms.created' => @course.created_at.iso8601,
      'dcterms.modified' => @course.updated_at.iso8601,
      og: {
        # mandatory:
        title: @course.title,
        type: 'website',
        image: og_image,
        url: Xikolo.base_url.join(course_path(@course.course_code)),
        # optional
        description: short_description&.truncate(150),
        site_name: Xikolo.config.site_name,
        'image:secure_url' => og_image,
        locale: @course.lang,
      },
    }

    meta[:noindex] = true if @course.hidden?

    meta
  end

  def status
    return 'external' if external_course_url.present?
    return 'preparation' unless published

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

  private

  # Returns the image URL used for the Open Graph `og:image` meta tag.
  #
  # Guards against blank values and the literal "null" string that can leak in
  # from course data (a JSON null serialized into a URL field). Without this,
  # the meta-tags gem would emit `og:image="null"`, which link-preview crawlers
  # resolve against the page URL (e.g. `/learn/null`). When no usable image is
  # available we return nil so the meta tag is omitted entirely.
  def og_image_url
    return if visual_url.blank? || visual_url.to_s.casecmp?('null')

    visual_url
  end

  def meta_keywords
    return if @course.classifiers.blank?

    @course.classifiers
      .where(cluster_id: %w[keywords topic])
      .map(&:title)
      .join(', ')
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
