# frozen_string_literal: true

class Successfactors::Course
  include ActionView::Helpers::DateHelper

  attr_reader :course, :config

  SF_LOCALES = {
    en: 'English',
    de: 'German',
    zh: 'Chinese',
    cn: 'Chinese',
    fr: 'French',
    ja: 'Japanese',
    bg: 'Bulgarian',
  }.freeze

  def initialize(course, config)
    @course = course
    @config = config
  end

  def as_ocn_data
    {
      courseID: course_code,
      providerID: config['provider_id'],
      status: course_status,
      title: [
        {
          locale: course_locale,
          value: course.title,
        },
      ],
      description: [
        locale: course_locale,
        value: course_description,
      ],
      thumbnailURI: course.visual&.image_url,
      content: [
        {
          providerID: config['provider_id'],
          contentTitle: course.title,
          contentID: course.id,
          launchURL: launch_url,
          launchType: 3,
          mobileEnabled: true,
        },
      ],
      price: [
        {
          currency: 'USD',
          value: 0.0,
        },
        {
          currency: 'EUR',
          value: 0.0,
        },
      ],
      schedule: [
        schedule_data,
      ],
    }
  end

  private

  # rubocop:disable Layout/LineLength
  def schedule_data
    schedule = {active: (course_status == 'ACTIVE')}
    if course.displayed_start_date
      schedule['startDate'] = course.displayed_start_date.to_datetime.to_i
    end
    schedule['endDate']   = course.end_date.to_datetime.to_i if course.end_date
    schedule['duration']  = if course.displayed_start_date && course.end_date
                              "#{((course.end_date.to_datetime.to_i - course.displayed_start_date.to_datetime.to_i) / 3600 / 24 / 7.0).ceil} weeks"
                            else
                              'unknown'
                            end
    schedule
  end
  # rubocop:enable Layout/LineLength

  def course_code
    return course.course_code unless course.deleted

    course.course_code.split('-deleted')[0]
  end

  def course_status
    return 'INACTIVE' if course.hidden ||
                         course.deleted ||
                         course.status == 'preparation'

    'ACTIVE'
  end

  def course_locale
    SF_LOCALES[course.lang.to_sym]
  end

  def course_description
    if course.abstract.present?
      render_markdown course.abstract
    else
      Xikolo::S3.externalize_file_refs(
        render_markdown(course.description),
        public: true
      )
    end
  end

  def launch_url
    template = Addressable::Template.new(@config['launch_url_template'])
    template.expand(
      host: Xikolo.base_url.host,
      course: course_code
    ).to_s
  end

  def render_markdown(markdown)
    Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        no_links: true
      )
    ).render(markdown).strip
  end
end
