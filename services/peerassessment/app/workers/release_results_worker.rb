# frozen_string_literal: true

class ReleaseResultsWorker
  include Sidekiq::Job

  def perform(peer_assessment_id, step_id)
    logger.info "[#{peer_assessment_id}] Releasing grades..."
    shared_submissions = SharedSubmission.joins(:submissions).where(
      peer_assessment_id:,
      submitted: true
    )
    submissions = shared_submissions.flat_map(&:submissions)

    step = Step.find step_id
    step.with_lock do
      step.deadline_worker_jids_will_change!
      step.deadline_worker_jids.reject! {|rjid| rjid == jid }
      step.save!
    end

    submissions.each do |submission|
      submission.write_course_result(create: true, recompute: true)
    end

    logger.info "[#{peer_assessment_id}] Done"
  end
end
