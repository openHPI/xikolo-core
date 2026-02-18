# frozen_string_literal: true

class Home::ChannelsController < Abstract::FrontendController
  before_action :ensure_canonical_channel_url, only: %i[show]

  COURSES_PER_PAGE = 12

  def show
    @channel = Home::ChannelPresenter.new(channel_resource)
    set_meta_tags @channel.meta_tags

    courses = Catalog::Course.released
      .for_channel_list(channel_resource)
      .for_user(current_user)

    Course::Cluster.ids.each do |cluster|
      courses = courses.by_classifier(cluster, params[cluster]) if params[cluster].present?
    end

    if params[:lang].present?
      courses = courses.where(lang: params[:lang])
    end

    if params[:q].present?
      courses = courses.search_by_text(params[:q])
    end

    @enrollments = enrollments_hash(courses)

    # Self-paced courses are paginated and rendered asynchronously via ajax
    if request.xhr? && params[:page].present?
      courses = courses.self_paced.paginate(page: params[:page], per_page: COURSES_PER_PAGE)

      response.set_header('Cache-Control', 'no-store')
      response.set_header('X-Current-Page', courses.current_page.to_s)
      response.set_header('X-Total-Pages', courses.total_pages.to_s)

      return render partial: 'home/courses/courses', locals: {courses:, enrollments: @enrollments}
    end

    @categories = categorize courses

    @course_list = Home::CourseListPresenter.new courses
  end

  private

  def channel_resource
    @channel_resource ||= begin
      Course::Channel.by_identifier(params[:id]).take!
    rescue ActiveRecord::RecordNotFound
      raise Status::NotFound
    end
  end

  def ensure_canonical_channel_url
    # Check if we're at the canonical URL, means the parameter is
    # the correct written channel code.
    return if channel_resource.code == params[:id]

    redirect_to channel_url(channel_resource.code), status: :see_other
  end

  Category = Struct.new(:title, :courses, :callout)
  private_constant :Category

  def categorize(scope)
    categories = [
      current_courses(scope),
      upcoming_courses(scope),
      self_paced_courses(scope),
    ]

    # Only display categories that have courses to show.
    # NOTE: We call load to prevent additional queries (for existence) before
    # later loading the actual records when displaying them.
    categories.reject {|category| category.courses.load.empty? }
  end

  def current_courses(scope)
    Category.new(t(:'course.courses.index.current'), scope.current)
  end

  def upcoming_courses(scope)
    Category.new(t(:'course.courses.index.upcoming'), scope.upcoming)
  end

  def self_paced_courses(scope)
    Category.new(
      t(:'course.courses.index.archive'),
      scope.self_paced.paginate(page: 1, per_page: COURSES_PER_PAGE)
    ).tap do |category|
      if feature?('course_reactivation') && CourseReactivation.enabled?
        category.callout = t(:'course.courses.index.reactivation_upsell_html')
      end
    end
  end

  # Load all of the user's enrollments into a hash (keyed by course ID) so that
  # they can be looked up and passed into each course's card component.
  # This is needed for action buttons on the cards being rendered depending on
  # whether an enrollment exists, whether it's reactivated etc.
  def enrollments_hash(courses)
    return {} if current_user.anonymous?

    Course::Enrollment.active
      .where(user_id: current_user.id)
      .where(course_id: courses.select(:id))
      .index_by(&:course_id)
  end
end
