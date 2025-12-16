# frozen_string_literal: true

module CourseService
class CourseDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all
  decorates_association :classifiers

  def as_api_v1(opts = {})
    fields.merge(
      url: h.course_path(self),
      prerequisite_status_url: h.prerequisite_status_course_url(self),
      achievements_url: h.course_achievements_url(self)
    ).as_json(opts)
  end

  def as_api_v2(opts = {})
    {
      id: object.id,
      course_code: object.course_code,
      title: object.title,
      abstract: object.abstract,
      teachers: object.teacher_text,
      language: object.lang,
      channel_code: object.channel&.code,
      classifiers:,
      state: object.state,
      hidden: object.hidden,
      accessible: object.accessible?,
      invite_only: object.invite_only,
      proctored: object.proctored,
      on_demand: model.allows_reactivation?,
      start_date: object.displayed_start_date&.iso8601,
      end_date: object.end_date&.iso8601,
      roa_threshold_percentage: object.roa_threshold_percentage,
      cop_threshold_percentage: object.cop_threshold_percentage,
      roa_enabled: object.roa_enabled,
      cop_enabled: object.cop_enabled,
      created_at: model.created_at,
      updated_at: model.updated_at,
      learning_goals: object.learning_goals,
      target_groups: object.target_groups,
      show_on_list: object.show_on_list,
    }.tap do |attrs|
      if object.enrollable?
        attrs[:enrollments_url] = h.enrollments_path(course_id: object.id)
      end
      if object.external_course_url.present?
        attrs[:external_course_url] = object.external_course_url
      end
      attrs[:policy_url] = object.policy_url if object.policy_url.present?
      attrs[:description] = description_v2 if embed?('description')
      attrs[:enrollment] = enrollment if embed?('enrollment')
    end.as_json(opts)
  end

  def as_event(**opts)
    context[:collection] = true
    fields.as_json(opts)
  end

  def self.account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  private
  def fields
    {
      id:,
      title:,
      start_date: start_date.nil? ? nil : start_date.iso8601,
      display_start_date: displayed_start_date&.iso8601,
      middle_of_course: model.middle_of_course&.iso8601,
      middle_of_course_is_auto: middle_of_course_is_auto?,
      end_date: end_date.nil? ? nil : end_date.iso8601,
      abstract:,
      lang:,
      classifiers:,
      teacher_ids:,
      course_code:,
      context_id:,
      special_groups:,
      status:,
      records_released:,
      enrollment_delta:,
      alternative_teacher_text:,
      external_course_url:,
      forum_is_locked:,
      public: object.public?,
      hidden:,
      show_on_list:,
      proctored:,
      welcome_mail:,
      auto_archive:,
      show_syllabus:,
      invite_only:,
      channel_id:,
      channel_code: model.channel&.code,
      channel_name: model.channel&.title_translations&.dig('en'),
      show_on_stage:,
      stage_visual_url:,
      stage_statement:,
      pinboard_enabled:,
      policy_url:,
      on_demand:,
      enable_video_download:,
      roa_threshold_percentage: model.roa_threshold_percentage,
      cop_threshold_percentage: model.cop_threshold_percentage,
      roa_enabled: model.roa_enabled,
      cop_enabled: model.cop_enabled,
      video_course_codes:,
      rating_stars:,
      rating_votes:,
      created_at: model.created_at,
      updated_at: model.updated_at,
      students_group_url:,
      learning_goals: object.learning_goals,
      target_groups: object.target_groups,
    }.tap do |attrs|
      %i[teacher_text].each do |field|
        next unless model.respond_to? field

        attrs[field] = model.send field
      end
      if external_registration?
        attrs[:external_registration_url] = model.external_registration_url
      end
      attrs[:description] = description_v1 unless in_collection?
      attrs[:groups] = groups if raw?
    end
  end

  # This enforces that the external_registration_url field will only be send
  # whenever necessary, that means, once the course is invite-only and has
  # external registration url(s) present, or on a context where the raw
  # model is requested (e.g. the admin interface)
  def external_registration?
    (model.invite_only? && model.external_registration_url.present?) || raw?
  end

  def classifiers
    list_hash = Hash.new {|h, k| h[k] = [] }

    # Make sure classifiers are sorted by 'cluster_id' (first field) and
    # 'title' (second field) to ensure there is a consistent ordering.
    raw_classifiers.sort.each_with_object(list_hash) do |classifier, hash|
      hash[classifier[0]] << classifier[1]
    end
  end

  def raw_classifiers
    if model.attributes.key? 'fixed_classifiers'
      model.fixed_classifiers.map {|c| c.values_at('cluster_id', 'title') }
    else
      model.classifiers.pluck(:cluster_id, :title)
    end
  end

  def enrollment
    if context[:enrollment]
      enrollment = context[:enrollment].with_course(object)
    elsif object.respond_to?(:enrollment) && !object.enrollment.nil?
      enrollment = Enrollment.instantiate_from_learning_evaluation(
        object.enrollment, object
      )
    else
      return nil
    end

    EnrollmentDecorator.new(enrollment).as_json(api_version: 2)
  end

  def description_v2
    Xikolo::S3.externalize_file_refs(object.description, public: true)
  end

  def description_v1
    if raw?
      Xikolo::S3.media_refs(object.description, public: true)
        .merge('markup' => object.description)
    else
      Xikolo::S3.externalize_file_refs(object.description, public: true)
    end
  end

  def students_group_url
    self.class.account_api
      .rel(:group).expand(id: object.students_group_name).to_s
  end

  def embed?(obj)
    context[:embed]&.include?(obj.to_s)
  end

  def raw?
    context[:raw]
  end

  def in_collection?
    context[:collection]
  end
end
  # rubocop:enable all
end
