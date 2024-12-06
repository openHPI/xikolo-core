# frozen_string_literal: true

class QuizSubmissionProctoringPresenter
  # @param proctoring [Quiz::Submission::Proctoring]
  def initialize(proctoring)
    @proctoring = proctoring
  end

  def status_callout
    if result.empty?
      Global::Callout.new(
        I18n.t(:'quiz_submission.proctoring.data_currently_unavailable'),
        icon: Global::FaIcon.new('gears', style: :solid),
        type: :warning
      )
    elsif result.perfect?
      Global::Callout.new(I18n.t(:'quiz_submission.proctoring.no_issues'), type: :success)
    elsif result.valid?
      Global::Callout.new(I18n.t(:'quiz_submission.proctoring.passed_with_issues'), type: :success)
    else
      Global::Callout.new(I18n.t(:'quiz_submission.proctoring.not_passed'), type: :error)
    end
  end

  def result
    @proctoring.results
  end
end
