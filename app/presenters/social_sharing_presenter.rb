# frozen_string_literal: true

class SocialSharingPresenter
  TRACKING_VERBS = {
    course: 'share_course',
      certificate: 'share_open_badge',
  }.freeze

  def initialize(context:, options: {})
    @context = context
    @processor =
      case context
        when :course
          CourseSharingProcessor.new(options)
        when :certificate
          CertificateSharingProcessor.new(options)
        else
          raise 'unknown sharing context'
      end
  end

  def url_for(service)
    @processor.url_for service
  end

  def tracking_verb
    TRACKING_VERBS[@context]
  end

  class SharingProcessor
    SHARING_URLS = {
      facebook: 'https://www.facebook.com/sharer/sharer.php?u=',
      twitter: 'https://twitter.com/intent/tweet?text=',
      linkedin_add: 'https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME',
      mail: 'mailto:',
    }.freeze

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def url_for(service)
      # implement in subclasses
    end
  end

  class CourseSharingProcessor < SharingProcessor
    def url_for(service)
      case service
        when 'twitter'
          %W[
            #{SHARING_URLS[:twitter]}
            #{ERB::Util.url_encode I18n.t(
              :'social_sharing.twitter.share_course',
              site: options[:site],
              title: options[:title]
            )}
            &url=#{options[:course_url]}
          ].join
        when 'mail'
          %W[
            #{SHARING_URLS[:mail]}
            ?subject=#{ERB::Util.url_encode I18n.t(
              :'social_sharing.mail.share_course.subject',
              site: options[:site]
            )}
            &body=#{ERB::Util.url_encode I18n.t(
              :'social_sharing.mail.share_course.body',
              site: options[:site],
              title: options[:title],
              url: options[:course_url]
            )}
          ].join
        else
          "#{SHARING_URLS[service.to_sym]}#{options[:course_url]}"
      end
    end
  end

  class CertificateSharingProcessor < SharingProcessor
    def url_for(service)
      case service
        when 'twitter'
          %W[
            #{SHARING_URLS[:twitter]}
            #{ERB::Util.url_encode I18n.t(
              :'social_sharing.twitter.share_certificate',
              site: options[:site],
              title: options[:title]
            )}
            &url=#{options[:certificate_url]}
          ].join
        when 'linkedin_add'
          args = {
            certId: options[:site],
            certUrl: options[:certificate_url],
            issueYear: options[:issued_year],
            issueMonth: options[:issued_month],
            name: options[:title],
            organizationId: Xikolo.config.linkedin_organization_id,
          }.compact
          "#{SHARING_URLS[:linkedin_add]}&#{args.to_query}"
        when 'mail'
          %W[
            #{SHARING_URLS[:mail]}
            ?subject=#{ERB::Util.url_encode I18n.t(
              :'social_sharing.mail.share_certificate.subject',
              site: options[:site]
            )}
            &body=#{ERB::Util.url_encode I18n.t(
              :'social_sharing.mail.share_certificate.body',
              site: options[:site],
              title: options[:title],
              certificate_url: options[:certificate_url],
              course_url: options[:course_url]
            )}
          ].join
        else
          "#{SHARING_URLS[service.to_sym]}#{options[:certificate_url]}"
      end
    end
  end
end
