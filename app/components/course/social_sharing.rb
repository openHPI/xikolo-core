# frozen_string_literal: true

module Course
  class SocialSharing < ApplicationComponent
    TRACKING_VERBS = {certificate: 'share_open_badge'}.freeze

    def initialize(context:, services: [], options: {})
      @context = context
      @services = services
      @options = options

      @processor =
        case context
          when :certificate
            CertificateSharingProcessor.new(options)
          else
            raise 'unknown sharing context'
        end
    end

    def build_url_for(service)
      @processor.build_url_for service
    end

    def tracking_verb
      TRACKING_VERBS[@context]
    end

    class SharingProcessor
      SHARING_URLS = {
        facebook: 'https://www.facebook.com/sharer/sharer.php?u=',
        linkedin_add: 'https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME',
        mail: 'mailto:',
      }.freeze

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def build_url_for(service)
        # implement in subclasses
      end
    end

    class CertificateSharingProcessor < SharingProcessor
      def build_url_for(service)
        case service
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
end
