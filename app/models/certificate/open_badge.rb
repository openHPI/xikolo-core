# frozen_string_literal: true

require 'xikolo/s3'
require 'addressable/uri'

module Certificate
  class OpenBadge < ::ApplicationRecord
    include Rails.application.routes.url_helpers

    HOST = Xikolo.base_url.host
    SCHEME = Xikolo.base_url.scheme
    # Map "type" column values to concrete subclasses.
    # NOTE: This can be used to map obsolete values to newer classes, or when
    # renaming models.
    STI_TYPE_TO_CLASS = {
      'OpenBadge' => '::Certificate::OpenBadge',
      'V2::OpenBadge' => '::Certificate::V2::OpenBadge',
    }.freeze

    # What "type" should be used when storing each subclass?
    STI_CLASS_TO_TYPE = {
      'Certificate::OpenBadge' => 'OpenBadge',
      'Certificate::V2::OpenBadge' => 'V2::OpenBadge',
    }.freeze

    belongs_to :record, class_name: '::Certificate::Record'
    belongs_to :open_badge_template,
      class_name: '::Certificate::OpenBadgeTemplate',
      foreign_key: :template_id,
      inverse_of: :open_badges

    class << self
      ##
      # Resolve the concrete subclass to use for a value of the type column.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#find_sti_class.
      def find_sti_class(type_name)
        if (cls = STI_TYPE_TO_CLASS[type_name])
          cls.constantize
        else
          raise SubclassNotFound.new("Unsupported badge type: #{type_name}")
        end
      end

      ##
      # Determine the type identifier to use as "type" when storing a concrete subclass.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#sti_name.
      def sti_name
        STI_CLASS_TO_TYPE.fetch(name)
      end

      def issue_count(course_id = nil)
        return count unless course_id

        template = OpenBadgeTemplate.find_by(course_id:)
        return unless template

        where(open_badge_template: template).count
      end
    end

    def baked?
      file_uri?
    end

    def bake!
      return if baked?

      raise InvalidAssertion if the_assertion.blank?

      badge = OpenBadgeBakery.new(
        the_assertion,
        open_badge_template.file_url,
        Rails.application.secrets.open_badge_private_key
      ).bake

      raise BakingFailed unless badge

      update!(file_uri: store_badge_file(badge).storage_uri, assertion: the_assertion)
    end

    def file_url
      return unless file_uri?

      # return public download url
      Xikolo::S3.object(file_uri).public_url
    end

    def file_key
      uid = UUID4(record.user_id).to_s(format: :base62)
      rid = UUID4(record.id).to_s(format: :base62)

      "openbadges/#{uid}/#{rid}.png"
    end

    protected

    def the_assertion
      @the_assertion ||= begin
        {
          '@context': 'https://w3id.org/openbadges/v1',
          type: 'Assertion',
          uid: UUID4(id).to_s(format: :base62),
          id: public_assertion_url,
          recipient: {
            type: 'email',
            hashed: 'true',
            identity: "sha256$#{Digest::SHA256.hexdigest record.user.email}",
          },
          badge: public_badge_url,
          issuedOn: issue_date.iso8601,
          verify: {
            type: 'signed',
            url: Addressable::URI.parse(Xikolo.base_url).join('openbadges/public_key.json').to_s,
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
        .join("assertion/#{UUID4(id).to_s(format: :base62)}.json")
        .to_s
    end

    def public_badge_url
      Addressable::URI.parse(public_course_url).join('badge.json').to_s
    end

    def public_course_url
      course_url(
        record.course['course_code'],
        host: HOST,
        protocol: SCHEME
      ).concat('/')
    end

    def issue_date
      date = record.enrollment['completed_at'] ||
             record.course.end_date ||
             Date.current
      Date.parse(date.to_s)
    end

    def store_badge_file(baked_badge)
      bucket = Xikolo::S3.bucket_for(:certificate)

      bucket.put_object(
        key: file_key,
        body: baked_badge,
        acl: 'public-read',
        content_type: 'image/png',
        content_disposition: 'attachment; ' \
                             "filename=\"#{record.course.course_code}_open_badge.png\""
      )
    rescue StandardError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      raise BakingFailed
    end

    class BakingFailed < RuntimeError; end

    class InvalidAssertion < RuntimeError; end
  end
end
