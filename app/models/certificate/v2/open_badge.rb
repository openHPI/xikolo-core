# frozen_string_literal: true

require 'xikolo/s3'

module Certificate
  module V2
    class OpenBadge < ::Certificate::OpenBadge
      protected

      def the_assertion
        @the_assertion ||= begin
          {
            '@context': 'https://w3id.org/openbadges/v2',
            type: 'Assertion',
            id: public_assertion_url,
            recipient: {
              type: 'email',
              hashed: true,
              identity: "sha256$#{Digest::SHA256.hexdigest record.user.email}",
            },
            badge: public_badge_url,
            issuedOn: issue_date.to_datetime.utc.iso8601,
            verification: {
              type: 'signed',
              creator: Addressable::URI.parse(Xikolo.base_url).join('openbadges/v2/public_key.json').to_s,
            },
            evidence: certificate_verification_url(
              id: record.verification,
              host: HOST,
              protocol: SCHEME
            ),
          }
        rescue TypeError
          # For example, this will occur when the user has no email, such
          # as for deleted users.
          {}
        end
      end

      private

      def public_assertion_url
        Addressable::URI.parse(public_course_url)
          .join("openbadges/v2/assertion/#{id}")
          .to_s
      end

      def public_badge_url
        Addressable::URI.parse(public_course_url).join('openbadges/v2/class.json').to_s
      end
    end
  end
end
