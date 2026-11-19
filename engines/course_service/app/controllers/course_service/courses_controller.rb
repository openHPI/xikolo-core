# frozen_string_literal: true

module CourseService
class CoursesController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: %i[
    autocomplete
    per_page
    public
    placement
    exclude_external
    latest_first
    alphabetic
    active_after
  ]
  def index
    if params.key?(:my_courses) ||
       params.key?(:my_upcoming) ||
       (params[:groups] && params[:groups] != 'any')
      return head :bad_request
    end

    courses = Course.from('embed_courses AS courses')
      .not_deleted.includes(:channels).order(start_date: :desc)

    # For now exclude all courses with group restrictions except
    #   1) User enrolled courses are requested (user_id filter)
    #   2) Explicit filter for groups, for now only with the value 'any'
    #      (no filter for specific groups)
    courses = courses.where(groups: []) if params[:groups] != 'any'

    # Filter the title by a given string
    if params[:autocomplete].present?
      courses = courses.autocomplete(params[:autocomplete])
    end

    if params[:exclude_external] == 'true'
      courses.where!(external_course_url: [nil, ''])
    end

    if params[:placement].present?
      courses.where!('placement::text[] && ARRAY[?]::text[]', params[:placement])
    end

    if params[:public] == 'true'
      courses.where! published: true
      courses.where! placement: ['Open4All']
    end

    if params[:active_after].present?
      date = Date.strptime params[:active_after]
      courses.where!('end_date is null or end_date > ?', date)
    end

    courses.reorder! 'created_at DESC' if params[:latest_first].present?

    courses.reorder! 'course_code ASC' if params[:alphabetic].present?

    respond_with courses
  end

  def show
    course = Course.not_deleted.by_identifier(params[:id])
      .from('embed_courses AS courses').take!

    respond_with course
  end

  def create
    ccp = course_create_params
    ccp.merge! classifier_params if params[:classifiers]
    respond_with Course::Create.call ccp
  end

  def update
    course = Course.by_identifier(params[:id]).take!
    cp = course_params
    cp.merge! classifier_params if params[:classifiers]
    respond_with Course::Update.call course, cp
  end

  def destroy
    course = Course.by_identifier(params[:id]).take!
    respond_with Course::Destroy.call course
  end

  def max_per_page
    500
  end

  def decoration_context
    {
      collection: action_name == 'index',
      raw: action_name != 'index' && params[:raw],
      embed: if action_name == 'index'
               []
             else
               params[:embed].to_s.split(',').map(&:strip)
             end,
    }
  end

  private
  def course_params
    params.permit(
      :title,
      :course_format,
      :start_date,
      :display_start_date,
      :lang,
      :end_date,
      :description,
      :abstract,
      :course_code,
      :forum_is_locked,
      :records_released,
      :enrollment_delta,
      :alternative_teacher_text,
      :invite_only,
      :external_course_url,
      :welcome_mail,
      :middle_of_course,
      :pinboard_enabled,
      :on_demand,
      :roa_threshold_percentage,
      :cop_threshold_percentage,
      :roa_enabled,
      :cop_enabled,
      :enable_video_download,
      :published,
      video_course_codes: [],
      teacher_ids: [],
      channel_ids: [],
      learning_goals: [],
      groups: [],
      placement: []
    ).tap do |white_listed|
      # see http://guides.rubyonrails.org/security.html#unsafe-query-generation
      if params.key?(:teacher_ids) && params[:teacher_ids].blank?
        white_listed[:teacher_ids] = []
      end
    end
  end

  def course_create_params
    params.permit(
      :title,
      :course_format,
      :start_date,
      :display_start_date,
      :lang,
      :id,
      :end_date,
      :description,
      :abstract,
      :course_code,
      :forum_is_locked,
      :records_released,
      :enrollment_delta,
      :alternative_teacher_text,
      :invite_only,
      :external_course_url,
      :welcome_mail,
      :middle_of_course,
      :pinboard_enabled,
      :on_demand,
      :roa_threshold_percentage,
      :cop_threshold_percentage,
      :roa_enabled,
      :cop_enabled,
      :published,
      video_course_codes: [],
      teacher_ids: [],
      learning_goals: [],
      groups: [],
      placement: []
    )
  end

  def classifier_params
    return {classifiers: []} if params[:classifiers].blank?

    {
      classifiers: params[:classifiers].permit!.select do |cluster, values|
        known_clusters.include?(cluster)
          && (values.is_a?(Array) || values.nil?)
      end,
    }
  end

  def known_clusters
    @known_clusters ||= Cluster.ids
  end
end
end
