# frozen_string_literal: true

module Course
  class Channel < ::ApplicationRecord
    has_many :courses, dependent: :nullify

    class << self
      def by_identifier(param)
        where(code: param).or where(id: UUID4.try_convert(param))
      end

      def not_deleted
        where(archived: false)
      end

      def public
        where(archived: false, public: true)
      end

      def ordered
        order(:position, :code)
      end
    end

    ##
    # Stage courses shown on the channels page.
    # Excludes deleted, hidden, and group-restricted courses even if they
    # are marked as stage items (`show_on_stage`). Also, it ignores courses
    # in preparation. Consequently, only publicly available courses
    # for all users are shown.
    #
    def stage_courses
      courses
        .not_deleted
        .where(hidden: false)
        .where(groups: [])
        .where(status: %w[active archive])
        .where(show_on_stage: true)
    end

    def logo_url
      Xikolo::S3.object(logo_uri).public_url if logo_uri?
    end
  end
end
