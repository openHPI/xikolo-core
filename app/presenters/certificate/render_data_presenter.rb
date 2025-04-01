# frozen_string_literal: true

require 'xikolo/s3'
require 'arabic-letter-connector'

module Certificate
  class RenderDataPresenter
    def initialize(record, template)
      @record = record
      @template = template
    end

    def dynamic_content
      return '' if @template.dynamic_content.blank?

      dynamic_content = I18n.with_locale(course_lang) do
        @template.dynamic_content.gsub(/##(\w+)##/) do
          lookup(Regexp.last_match(1))
        end
      end

      fix_text_direction dynamic_content
    end

    def qrcode_url
      verification_url
    end

    def qrcode_pos
      return false if @template.certificate_type == ::Certificate::Record::TOR
      return false unless @template.qrcode_x.try(:positive?) &&
                          @template.qrcode_y.try(:positive?)

      {x: @template.qrcode_x, y: @template.qrcode_y}
    end

    def template_path
      # We keep a reference here to ensure the tempfile is deleted
      # after the rendering, not after leaving this method.
      template_file = Tempfile.new ['certtmpl-', '.pdf']
      object = Xikolo::S3.object(@template.file_uri)
      object.download_file(template_file.path, mode: 'single_request')
      template_file.path
    end

    def proctoring_image
      return unless @template.certificate_type == ::Certificate::Record::CERT

      enrollment = Course::Enrollment.find_by(
        user_id: @record.user_id,
        course: @record.course
      )
      image = enrollment&.proctoring&.s3_image
      unless image&.exists?
        raise InsufficientParams.new "can't find proctoring image for certificate"
      end

      # we keep a reference here to ensure the tempfile is deleted
      # after the rendering, not after leaving this method
      proctoring_image = Tempfile.new ['procimg-', '.jpg']
      image.download_file(proctoring_image.path, mode: 'single_request')
      proctoring_image.path
    end

    def score
      return if @template.certificate_type == ::Certificate::Record::COP

      {
        points: @record.enrollment['points']['achieved'].to_f.round(1),
        max_points: @record.enrollment['points']['maximal'].to_f.round(1),
        percent: @record.enrollment['points']['percentage'].to_f.round(1),
      }
    end

    def top_percent
      return unless @record.enrollment['quantile']

      top_percentage = (1 - @record.enrollment['quantile']).round(2)
      if top_percentage <= 0.05
        5
      elsif top_percentage <= 0.1
        10
      elsif top_percentage <= 0.2
        20
      end
    end

    def date_of_birth
      return if @record.user.born_at.blank?

      @record.user.born_at.to_date if @record.user.preferences['records.show_birthdate'] == 'true'
    end

    def issue_date
      if @record.enrollment['completed_at'].blank?
        @record.course.end_date&.to_date || Time.zone.today
      else
        Date.parse(@record.enrollment['completed_at'])
      end
    end

    def transcript_of_records
      return unless @template.certificate_type == ::Certificate::Record::TOR
      return if prerequisite_status['prerequisites'].blank?

      # Create Array structure for the transcript to be rendered as table.
      [
        # Add header lines
        [
          I18n.t(:'certificates.transcript_of_records.course', locale: course_lang),
          I18n.t(:'certificates.transcript_of_records.score', locale: course_lang),
        ],
        # Add courses with corresponding scores
        *prerequisite_status['prerequisites'].map do |p|
          [p['course']['title'], format_score(p['score'])]
        end,
        # Add overall score
        [
          I18n.t(:'certificates.transcript_of_records.overall_score', locale: course_lang),
          format_score(transcript_overall_score),
        ],
      ]
    end

    protected

    def lookup(var)
      wrap_in_cdata lookup_raw(var)
    end

    def lookup_raw(var)
      case var
        when 'NAME'
          @record.user.full_name
        when 'EMAIL'
          @record.user.email
        when 'EMAIL_V2'
          I18n.t(:'certificate.template.email_v2', email: @record.user.email)
        when /^GRADE($|_)/
          lookup_grade(var) if score
        when /^BIRTHDAY($|_)/
          lookup_birthday(var) if date_of_birth
        when /^TOP($|_)/
          lookup_top(var) if top_percent
        when 'VERIFY'
          I18n.t(:'certificate.template.verify', verification_url:)
        when 'ISSUED_AT'
          I18n.l(issue_date, format: :certificate)
        when 'ISSUED_AT_INTL'
          I18n.l(issue_date, locale: intl_date_format)
      end
    end

    def lookup_grade(var)
      case var
        when 'GRADE'
          I18n.t(:'certificate.template.score_v1', **score)
        when 'GRADE_V2'
          I18n.t(:'certificate.template.score_v2', **score)
        when 'GRADE_V3'
          I18n.t(:'certificate.template.score_v3', **score)
      end
    end

    def lookup_birthday(var)
      case var
        when 'BIRTHDAY'
          I18n.t(:'certificate.template.born_v1', birthday: I18n.l(date_of_birth, format: :certificate))
        when 'BIRTHDAY_V2'
          I18n.t(:'certificate.template.born_v2', birthday: I18n.l(date_of_birth, format: :certificate))
        when 'BIRTHDAY_V3'
          I18n.t(:'certificate.template.born_v3', birthday: I18n.l(date_of_birth, format: :certificate))
        when 'BIRTHDAY_INTL'
          I18n.t(
            :'certificate.template.born_v3',
            birthday: I18n.l(date_of_birth, locale: intl_date_format)
          )
      end
    end

    def lookup_top(var)
      case var
        when 'TOP'
          I18n.t(:'certificate.template.top_v1', top: top_percent)
        when 'TOP_V2'
          I18n.t(:'certificate.template.top_v2', top: top_percent)
      end
    end

    def course_lang
      if Xikolo.config.locales['available'].include?(@record.course.lang)
        return @record.course.lang
      end

      Xikolo.config.locales['default']
    end

    def intl_date_format
      @intl_date_format ||= if Xikolo.config.locales['available'].include? 'de'
                              'de'
                            else
                              Xikolo.config.locales['default']
                            end
    end

    def fix_text_direction(dynamic_content)
      return dynamic_content unless dynamic_content.strip.start_with? '<?xml'

      xml_doc = Nokogiri::XML dynamic_content

      rtl_scripts = /\p{Arabic}|\p{Hebrew}|\p{Nko}|\p{Syriac}/
      xml_doc.search('text').each do |text|
        next unless text.content.match?(rtl_scripts)

        # Setting the direction attribute to 'rtl' here does not work
        # Prawn doesn't respect that when rendering - this hack however
        # seems to be a close approximation
        text['direction'] = 'rtl'
        text.content = text.content.connect_arabic_letters.reverse
      end

      xml_doc.to_xml
    end

    def wrap_in_cdata(str)
      "<![CDATA[#{str}]]>"
    end

    private

    def verification_url
      return if @template.certificate_type == ::Certificate::Record::TOR

      Rails.application.routes.url_helpers.certificate_verification_url(
        id: @record.verification,
        host: Xikolo.config.base_url.site
      )
    end

    def prerequisite_status
      @prerequisite_status ||= Xikolo.api(:course).value!.rel(:prerequisite_status)
        .get({id: @record.course_id, user_id: @record.user_id})
        .value!
    end

    def transcript_overall_score
      return unless @template.certificate_type == ::Certificate::Record::TOR

      prerequisite_status['prerequisites']
        .filter_map { _1['score'].to_f if _1['required_certificate'] == 'roa' }
        .then {|scores| scores.sum.fdiv(scores.count) }
    end

    def format_score(score)
      case score
        when Numeric
          "#{score.round(1)}%"
        when String
          "#{score.to_f.round(1)}%"
        when true
          I18n.t(:'certificates.transcript_of_records.passed', locale: course_lang)
        else
          raise TypeError
      end
    end

    class InsufficientParams < StandardError; end
  end
end
