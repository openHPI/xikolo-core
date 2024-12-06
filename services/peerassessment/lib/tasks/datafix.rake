# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Fixing some data in the prototype test.
  DESC

  task fix: :environment do
    PeerAssessment.find_each do |assessment|
      assessment.grading_pool.pool_entries.each do |entry|
        next if entry.submission.submitted

        # Take the users back to the first step
        participant = Participant.find_by!(user_id: entry.submission.user_id, peer_assessment_id: assessment.id)

        participant.current_step = assessment.steps.first.id
        participant.save validate: false

        # Kill reviews associated with the submission
        Review.where(submission_id: entry.submission_id).delete_all

        # Kill conflicts
        Conflict.where(conflict_subject_id: entry.submission_id).delete_all

        # Kill pool entry
        entry.destroy!
      end
    end

    $stdout.print '..fixing finished.'
    $stdout.flush
  end
end
