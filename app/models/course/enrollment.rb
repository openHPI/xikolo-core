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

    def proctoring
      return unless proctored?

      @proctoring ||= Proctoring.new(self)
    end
  end
end
