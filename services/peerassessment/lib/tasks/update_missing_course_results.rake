# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Creates missing results for a peer assessment and updates existing ones.
    In general, this should happen automatically. In some cases, it does not.
    So this task can be used to trigger it manually.
  DESC

  task :update_missing_course_results, [:assessment_id] => :environment do |_, args|
    assessment_id = args[:assessment_id]
    recompute_grades(assessment_id)
  end

  def recompute_grades(peer_assessment_id)
    shared_submissions = SharedSubmission.joins(:submissions).where(
      peer_assessment_id:,
      submitted: true
    )
    submissions = shared_submissions.flat_map(&:submissions)

    submissions.each do |submission|
      puts '=========================='
      puts submission.id
      puts '=========================='
      submission.write_course_result(create: true, recompute: true)
    end
  end
end
