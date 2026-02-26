# frozen_string_literal: true

module Course
  class Enrollment < ::ApplicationRecord
    belongs_to :course

    class << self
      def active
        where(deleted: false)
      end
    end

    def reactivated?
      forced_submission_date&.future?
    end
  end
end
