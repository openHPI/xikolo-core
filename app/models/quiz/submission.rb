# frozen_string_literal: true

module Quiz
  class Submission
    # This should become a real ActiveRecord model in the future.

    class << self
      def find(id)
        from_restify(
          Xikolo.api(:quiz).value!
            .rel(:quiz_submission).get(id:).value!
        )
      end

      def from_restify(resource)
        new resource
      end

      # @param resource [Xikolo::Submission::QuizSubmission]
      def from_acfs(resource)
        new resource.attributes
      end
    end

    def initialize(hash)
      @submission = hash
    end

    def proctoring
      @proctoring ||= Proctoring.new(@submission)
    end

    def proctored?
      @submission['vendor_data'].key?('proctoring') || @submission['vendor_data'].key?('proctoring_smowl')
    end
  end
end
