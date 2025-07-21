# frozen_string_literal: true

class CoursesController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: %i[
    cat_id
    user_id
    status
    id
    lang
    course_code
    upcoming
    per_page
    current
    finished
    public
    hidden
    only_hidden
    exclude_external
    latest_first
    alphabetic
    promoted_for
    not_enrolled
    middle_of_course
    document_id
    autocomplete
    active_after
    sort
  ]
  def index
    if params.key?(:my_courses) ||
       params.key?(:my_upcoming) ||
       (params[:groups] && params[:groups] != 'any')
      return head :bad_request
    end

    courses = Course.from('embed_courses AS courses')
      .not_deleted.includes(:channel)

    if params[:user_id].blank? &&
       params[:promoted_for].blank? &&
       params[:groups] != 'any'
      # For now exclude all courses with group restrictions except
      #   1) User enrolled courses are requested (user_id filter)
      #   2) Promoted courses are requested (we can check user memberships)
      #   3) Explicit filter for groups, for now only with the value 'any'
      #      (no filter for specific groups)
      courses = courses.where(groups: [])
    end

    # Filter the title by a given string
    if params[:autocomplete].present?
      courses = courses.autocomplete(params[:autocomplete])
    end

    # Filter by category
    courses = courses.by_classifier(params[:cat_id]) if params[:cat_id].present?

    # Filter by channel
    courses.where!(channel_id: params[:channel_id]) if params[:channel_id]

    # Filter by document
    if params[:document_id]
      courses = courses.joins(:courses_documents)
        .where(courses_documents: {document_id: params[:document_id]})
    end

    # filter by user_id
    if params[:user_id].present?
      user_enrollments = Enrollment.active.where(user_id: params[:user_id])
        .select(:course_id)
      courses = if params[:not_enrolled].present?
                  courses.where.not(id: user_enrollments)
                else
                  courses.where(id: user_enrollments)
                end
    end

    courses.where! status: params[:status] if params[:status].present?
    courses.where! id: params[:id] if params[:id].present?
    courses.where! lang: params[:lang] if params[:lang].present?

    if params[:course_code].present?
      courses.where! course_code: params[:course_code]
    end
    if params[:exclude_external] == 'true'
      courses.where!(external_course_url: [nil, ''])
    end
    if params[:only_hidden] == 'true'
      courses.where! hidden: true
    elsif params[:hidden] == 'false'
      courses.where! hidden: false
    end
    if params[:upcoming].present?
      courses.where! status: 'active'
      courses.where! '(start_date > ? AND display_start_date IS NULL)
        OR display_start_date > ?', ::Time.zone.now, ::Time.zone.now
      courses.reorder! Arel.sql('GREATEST(start_date, display_start_date) ASC')
    end

    if params[:current].present?
      courses.where! status: 'active'
      courses.where! '(start_date <= ? AND display_start_date IS NULL)
        OR display_start_date <= ? OR start_date IS NULL', ::Time.zone.now, ::Time.zone.now
      courses.where! 'end_date >= ? OR end_date IS NULL', ::Time.zone.now
    end

    if params[:finished].present?
      courses.where! "(status = 'archive' OR
        (status = 'active' AND end_date IS NOT NULL AND end_date < ? ))",
        ::Time.zone.now
    end

    if params[:public] == 'true'
      allowed_status = %w[archive active]
      courses.where!(status: allowed_status)
    end

    if params[:active_after].present?
      date = Date.strptime params[:active_after]
      courses.where!('end_date is null or end_date > ?', date)
    end

    courses.reorder! 'created_at DESC' if params[:latest_first].present?

    courses.reorder! 'course_code ASC' if params[:alphabetic].present?

    case params[:sort]
      when 'started_recently_first'
        courses.reorder! Arel.sql('COALESCE(display_start_date, start_date) DESC, title ASC')
      when 'started_earliest_first'
        courses.reorder! Arel.sql('COALESCE(display_start_date, start_date) ASC, title ASC')
    end

    # dashboard filters
    if params[:promoted_for].present?
      courses = courses
        .for_groups(user: params[:promoted_for])
        .where(status: 'active', hidden: false)
        .where('end_date IS NULL OR end_date >= ?', ::Time.zone.now)

      user_enrollments = Enrollment.active
        .where(user_id: params[:promoted_for]).select(:course_id)
      courses = courses.where.not(id: user_enrollments)
      courses.reorder! Arel.sql('COALESCE(display_start_date, start_date)')
    end

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
    course = Course.find(params[:id])
    cp = course_params
    cp.merge! classifier_params if params[:classifiers]
    respond_with Course::Update.call course, cp
  end

  def destroy
    course = Course.find(params[:id])
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
      :start_date,
      :display_start_date,
      :lang,
      :end_date,
      :description,
      :abstract,
      :status,
      :hidden,
      :show_on_list,
      :proctored,
      :course_code,
      :forum_is_locked,
      :records_released,
      :enrollment_delta,
      :alternative_teacher_text,
      :show_syllabus,
      :channel_id,
      :invite_only,
      :external_course_url,
      :welcome_mail,
      :auto_archive,
      :middle_of_course,
      :show_on_stage,
      :stage_visual_upload_id,
      :stage_visual_uri,
      :stage_statement,
      :pinboard_enabled,
      :on_demand,
      :roa_threshold_percentage,
      :cop_threshold_percentage,
      :roa_enabled,
      :cop_enabled,
      :rating_stars,
      :rating_votes,
      :enable_video_download,
      video_course_codes: [],
      teacher_ids: [],
      channels: [],
      learning_goals: [],
      target_groups: [],
      groups: [],
      external_registration_url: Xikolo.config.locales['available']
    ).tap do |white_listed|
      if params[:policy_url]
        white_listed[:policy_url] = params[:policy_url].permit!
      end
      # see http://guides.rubyonrails.org/security.html#unsafe-query-generation
      if params.key?(:teacher_ids) && params[:teacher_ids].blank?
        white_listed[:teacher_ids] = []
      end
    end
  end

  def course_create_params
    params.permit(
      :title,
      :start_date,
      :display_start_date,
      :lang,
      :id,
      :end_date,
      :description,
      :abstract,
      :status,
      :hidden,
      :show_on_list,
      :proctored,
      :course_code,
      :forum_is_locked,
      :records_released,
      :enrollment_delta,
      :alternative_teacher_text,
      :show_syllabus,
      :channel_id,
      :invite_only,
      :external_course_url,
      :welcome_mail,
      :auto_archive,
      :middle_of_course,
      :show_on_stage,
      :stage_visual_upload_id,
      :stage_statement,
      :pinboard_enabled,
      :on_demand,
      :roa_threshold_percentage,
      :cop_threshold_percentage,
      :roa_enabled,
      :cop_enabled,
      :rating_stars,
      :rating_votes,
      video_course_codes: [],
      teacher_ids: [],
      learning_goals: [],
      target_groups: [],
      groups: [],
      external_registration_url: Xikolo.config.locales['available']
    ).tap do |white_listed|
      if params[:policy_url]
        white_listed[:policy_url] = params[:policy_url].permit!
      end
    end
  end

  def classifier_params
    return {classifiers: []} if params[:classifiers].blank?

    {
      classifiers: params[:classifiers].permit!.select do |cluster, values|
        known_clusters.include?(cluster) \
          && (values.is_a?(Array) || values.nil?)
      end,
    }
  end

  def known_clusters
    @known_clusters ||= Cluster.ids
  end
end
