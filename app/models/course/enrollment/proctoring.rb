# frozen_string_literal: true

module Course
  class Enrollment
    class Proctoring
      def initialize(enrollment)
        @enrollment = enrollment
      end

      def vendor_registration
        @vendor_registration ||= vendor.registration_status(@enrollment.user_id)
      end

      def vendor_registration_url(redirect_to:)
        vendor.registration_url(@enrollment.user_id, redirect_to:)
      end

      def load_certificate_image!
        return if s3_image.exists?

        vendor_image = vendor.fetch_image(@enrollment.user_id)
        return if vendor_image.blank?

        s3_image.put(
          body: vendor_image,
          acl: 'private',
          content_type: 'image/jpeg'
        )
      end

      def s3_image
        @s3_image ||= begin
          cid = UUID4(@enrollment.course_id).to_s(format: :base62)
          uid = UUID4(@enrollment.user_id).to_s(format: :base62)

          Xikolo::S3.bucket_for(:certificate).object(
            "proctoring/#{uid}/#{cid}.jpg"
          )
        end
      end

      private

      def vendor
        @vendor ||= ::Proctoring::SmowlAdapter.new(@enrollment.course)
      end
    end
  end
end
