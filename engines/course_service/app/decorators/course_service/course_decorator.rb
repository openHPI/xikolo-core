# frozen_string_literal: true

module CourseService
class CourseDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all
  decorates_association :classifiers

  def as_api_v1(opts = {})
    fields.merge(url: h.course_path(self)).as_json(opts)
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
      records_released:,
      enrollment_delta:,
      alternative_teacher_text:,
      external_course_url:,
      forum_is_locked:,
       public: object.public?,
       welcome_mail:,
      invite_only:,
      channels: object.channels.map do |ch|
        {
          id: ch.id,
          code: ch.code,
          title_translations: ch.title_translations,
        }
      end,
      pinboard_enabled:,
      on_demand:,
      enable_video_download:,
      published:,
      placement:,
      roa_threshold_percentage: model.roa_threshold_percentage,
      cop_threshold_percentage: model.cop_threshold_percentage,
      roa_enabled: model.roa_enabled,
      cop_enabled: model.cop_enabled,
      video_course_codes:,
      created_at: model.created_at,
      updated_at: model.updated_at,
      students_group_url:,
      learning_goals: object.learning_goals,
      course_format:,
    }.tap do |attrs|
      %i[teacher_text].each do |field|
        next unless model.respond_to? field

        attrs[field] = model.send field
      end
      attrs[:description] = description_v1 unless in_collection?
      attrs[:groups] = groups if raw?
    end
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
