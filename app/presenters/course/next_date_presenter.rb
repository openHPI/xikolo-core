# frozen_string_literal: true

class Course::NextDatePresenter
  def initialize(date, with_link: true)
    @next_date = date
    @with_link = with_link
  end

  include Rails.application.routes.url_helpers

  def date
    Time.zone.parse(@next_date['date'])
  end

  def resource_type
    @next_date['resource_type']
  end

  def course_title
    @next_date['course_title']
  end

  def id
    @next_date['type']
  end

  def description
    I18n.t("next_dates.#{id}", title: @next_date['title'])
  end

  def summary
    case id
      when 'course_start', 'section_start', 'item_submission_deadline'
        I18n.t("ical.#{id}", title: @next_date['title'], course_title:)
      # when 'item_submission_publishing'
    end
  end

  def static_description
    case id
      when 'course_start', 'section_start', 'item_submission_deadline'
        I18n.t("ical.#{id}_desc", title: @next_date['title'], course_title:, site: Xikolo.config.site_name)
      # when 'item_submission_publishing'
    end
  end

  def date_obj
    date
  end

  def do_url
    return unless @with_link

    case id
      when 'course_start'
        course_path(@next_date['course_code'])
      when 'on_demand_expires'
        course_resume_path(@next_date['course_code'])
      when 'item_submission_deadline'
        course_item_path(@next_date['course_code'], UUID(@next_date['resource_id']).to_param)
    end
  end

  # used for ical
  def do_full_url
    case id
      when 'course_start', 'section_start'
        Xikolo.base_url.join course_path(@next_date['course_code'])
      when 'on_demand_expires'
        Xikolo.base_url.join course_resume_path(@next_date['course_code'])
      when 'item_submission_deadline'
        Xikolo.base_url.join course_item_path(@next_date['course_code'], UUID(@next_date['resource_id']).to_param)
    end
  end
end
