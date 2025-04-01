# frozen_string_literal: true

module Course
  class Enrollment
    class Proctoring
      def initialize(enrollment)
        @enrollment = enrollment
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
