# frozen_string_literal: true

class Home::CoursesController < Abstract::FrontendController
  include Interruptible

  PER_PAGE = 12

  def index
    set_page_title t(:'header.meta_tags.courses.title')

    courses = Catalog::Course.released.for_global_list.for_user(current_user)

    if params[:channel].present?
      channel = CourseService::Channel.by_identifier(params[:channel]).take
      courses = courses.joins(:channels).merge(CourseService::Channel.where(id: channel)) if channel
    end

    CourseService::Cluster.ids.each do |cluster|
      courses = courses.by_classifier(cluster, params[cluster]) if params[cluster].present?
    end

    if params[:lang].present?
      courses = courses.where(lang: params[:lang])
    end

    if CourseService::Course.course_formats.key?(params[:course_format])
      courses = courses.where(course_format: params[:course_format])
    end

    if params[:q].present?
      courses = courses.search_by_text(params[:q])
    end

    @enrollments = enrollments_hash

    # Self-paced courses are paginated and rendered asynchronously via ajax
    if request.xhr? && params[:page].present?
      courses = courses.self_paced.paginate(page: params[:page], per_page: PER_PAGE)

      response.set_header('X-Current-Page', courses.current_page.to_s)
      response.set_header('X-Total-Pages', courses.total_pages.to_s)

      return render partial: 'home/courses/courses', locals: {courses:, enrollments: @enrollments}
    end

    @categories = categorize courses

    @filtered_list = filtered_list?

    @featured_course = featured_course_from courses

    @course_list = Home::CourseListPresenter.new courses
  end

  private

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
      scope.self_paced.paginate(page: 1, per_page: PER_PAGE)
    )
  end

  # Load evaluated enrollments once for completion badges.
  def enrollments_hash
    return {} if current_user.anonymous?

    CourseService::Enrollment.active.with_evaluation.where(user_id: current_user.id).index_by(&:course_id)
  end

  def filtered_list?
    filters = CourseService::Cluster.ids + %w[channel lang course_format q]
    filters.any? { params[it].present? }
  end

  def featured_course_from(scope)
    return if filtered_list?

    scope.by_classifier('course-list', 'Featured').take
  end
end
