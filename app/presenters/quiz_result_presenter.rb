# frozen_string_literal: true

class QuizResultPresenter
  include ProgressHelper

  def initialize(quiz, submission, all_submissions)
    @quiz = quiz
    @submission = submission
    @all_submissions = all_submissions
  end

  ##
  # Determine the achieved percentage in the current submission
  #
  def percentage
    calc_progress(@submission['points'], @quiz['max_points'])
  end

  ##
  # Assemble the data for the chart of historic submissions (points over time)
  #
  def history_graph_data
    @all_submissions.each_with_object({}) do |submission, hash|
      key = DateTime.iso8601(submission['quiz_submission_time']).as_json
      hash[key] = submission['points']
    end
  end

  ##
  # Generate the labels and IDs for selecting other submissions (e.g. for viewing them)
  #
  def submission_labels
    @all_submissions.map do |submission|
      [
        I18n.l(DateTime.iso8601(submission['quiz_submission_time']), format: :quiz_submission),
        UUID(submission['id']).to_param,
      ]
    end
  end
end
