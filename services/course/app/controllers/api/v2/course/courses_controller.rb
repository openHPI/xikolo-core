# frozen_string_literal: true

class API::V2::Course::CoursesController < API::V2::RootController
  include Authenticate

  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: %i[embed channel document_id]
  def index
    enrolled_courses = if current_user.anonymous?
                         Enrollment.none
                       else
                         Enrollment.active.where(user_id: current_user.id)
                       end.select(:course_id)

    courses = collection

    courses = [
      courses.where(id: enrolled_courses),
      courses.published.where(hidden: false)
        .for_groups(user: current_user.id),
    ].reduce(:or)

    courses = courses.includes(:channel)

    respond_with courses
  end

  # List allowed filter parameters for #show here.
  rfc6570_params show: %i[embed raw]
  def show
    if course.status == 'preparation' \
      && !current_user.allowed?('course.content.access')
      raise RecordNotFound.new
    end
    raise NotAuthorized.new unless current_user.allowed?('course.course.show')

    respond_with course
  end

  def max_per_page
    500
  end

  def decoration_context
    {
      collection: action_name == 'index',
      raw: action_name != 'index' && params[:raw],
      enrollment: if action_name == 'show' && embed.include?('enrollment')
                    course_enrollment
                  end,
      embed:,
    }
  end

  private

  def auth_context
    course.context_id if action_name == 'show'
  end

  def collection
    courses = ::Course.from('embed_courses AS courses').not_deleted

    courses = apply_channel_filter(courses) if params[:channel]

    if params[:document_id]
      courses = courses.joins(:courses_documents)
      courses.where!(courses_documents: {document_id: params[:document_id]})
    end

    if current_user.logged_in? && embed.include?('enrollment')
      enrollment_data = LearningEvaluation.by_params({learning_evaluation: 'true'}).call(
        Enrollment.active.where(user_id: current_user.id)
      ).arel.as('enrollments')

      courses.joins(
        Enrollment.arel_table
          .join(enrollment_data, Arel::Nodes::OuterJoin)
          .on(Course.arel_table[:id].eq(enrollment_data[:course_id]))
          .join_sources
      ).select(
        'courses.*',
        'row_to_json(enrollments) AS enrollment'
      )
    else
      courses
    end
  end

  def course
    @course ||= ::Course.from('embed_courses AS courses').not_deleted
      .by_identifier(params[:id])
      .take!
  end

  def course_enrollment
    return if current_user.anonymous?

    enrollments = course.enrollments.active.where(user_id: current_user.id)
    if embed.include?('enrollment')
      enrollments = LearningEvaluation.by_params({learning_evaluation: 'true'}).call(enrollments)
    end
    enrollments.take
  end

  def apply_channel_filter(courses)
    channel = Channel.by_identifier(params[:channel]).take

    channel ? courses.where(channel_id: channel.id) : courses.none
  end

  def embed
    params[:embed].to_s.split(',').map(&:strip)
  end
end
