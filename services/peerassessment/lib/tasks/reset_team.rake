# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Resets the PeerAssessment of a team in case a new participant has been added.
    This cannot be run anymore once the training or review phase have started.
    Required arguments:
      assessment_id - the id of the peer_assessment
      user_id - the id of any of the original users of the CollabSpace whose PA requires to be reset
      team_name - the name of the team
    Optional argument:
      dry_run - true: just log what would be deleted, false: delete
    When calling the task make sure there is no space after the comma in the arguments
    rake xikolo:reset_team[pa_id,user_id,team_name,dry_run] RAILS_ENV=development
  DESC

  task :reset_team, %i[assessment_id user_id team_name dry_run] => :environment do |_, args|
    peer_assessment_id = args[:assessment_id]
    user_id = args[:user_id]
    team_name = args[:team_name]
    dry_run = %w[true t].include?(args[:dry_run])

    # 1. Gather Data
    participant = Participant.find_by(peer_assessment_id:, user_id:)
    if participant.nil?
      $stdout.puts 'There is no participant for the provided user_id'
    else
      group = Group.find(participant.group_id)
      participants = Participant.where(peer_assessment_id:, group_id: group.id)
      affected_user_ids = participants.map(&:user_id)

      # Log Participants
      inform('Participants', participants)

      if dry_run
        # Log Group
        inform('Group', group)
      else
        # Delete Participants
        participants&.destroy_all

        # Delete Group
        inform('Group', group)
        group&.destroy
      end

      shared_submission = SharedSubmission.joins(:submissions).where(
        peer_assessment_id:,
        submissions: {user_id:}
      ).first

      if shared_submission.nil?
        $stdout.puts 'SharedSubmission does not exist for this Team'
      else
        shared_submission_id = shared_submission.id
        submissions = Submission.where(shared_submission_id:)
        affected_submission_ids = submissions.map(&:id)
        pool_entries = PoolEntry.where(submission_id: affected_submission_ids)
        grades = Grade.where(submission_id: affected_submission_ids)

        # Log Shared_Submission
        inform('Shared_Submission', shared_submission)

        # 2. Clean up
        if dry_run
          # Log Submissions
          inform('Submissions', submissions)
          # Log Grades
          inform('Grades', grades)
          # Log PoolEntries
          inform('PoolEntries', pool_entries)
        else
          # Delete Shared_Submission
          shared_submission&.destroy
          # Delete Submissions
          inform('Submissions', submissions)
          submissions&.destroy_all
          # Delete Grades
          inform('Grades', grades)
          grades&.destroy_all
          # Delete PoolEntries
          inform('PoolEntries', pool_entries)
          pool_entries&.destroy_all
        end
      end

      members = Xikolo.api(:collabspace).value!
        .rel(:collab_spaces).get(name: team_name).value!.first
        .rel(:memberships).get(status: 'admin').value!

      members_ids = members.pluck('user_id')
      new_members_ids = members_ids - affected_user_ids

      $stdout.puts <<~TEXT.strip
        Team reset finished.
        You need to complete this task by deleting all old records \
        of the users that have been moved into the current team:
      TEXT

      $stdout.puts(new_members_ids.map do |x|
                     "xikolo-peerassessment rake xikolo:reset_moved_user[#{peer_assessment_id},#{x},true]"
                   end)
      $stdout.flush
    end
  end

  desc <<~DESC.strip
    Resets the old PeerAssessment data of a user that has been moved to a new team.
    This cannot be run anymore once the training or review phase have started.
    Required arguments:
      assessment_id - the id of the peer_assessment
      user_id - the id of the user that has been moved from another team
    Optional argument:
      dry_run - true: just log what would be deleted, false: delete
    When calling the task make sure there is no space after the comma in the arguments
    rake xikolo:reset_team[pa_id,user_id,dry_run] RAILS_ENV=development
  DESC
  task :reset_moved_user, %i[assessment_id user_id dry_run] => :environment do |_, args|
    peer_assessment_id = args[:assessment_id]
    user_id = args[:user_id]
    dry_run = %w[true t].include?(args[:dry_run])
    participant = Participant.find_by(user_id:, peer_assessment_id:)

    # Log Participant
    inform('Participant', participant)

    unless dry_run
      # Delete Participant
      participant&.destroy
    end

    shared_submission = SharedSubmission.joins(:submissions).where(
      peer_assessment_id:,
      submissions: {user_id:}
    ).first

    if shared_submission.nil?
      $stdout.puts 'SharedSubmission does not exist for this user'
    else
      shared_submission_id = shared_submission.id
      submission = Submission.find_by(user_id:, shared_submission_id:)
      pool_entry = PoolEntry.find_by(submission_id: submission.id)
      grade = Grade.find_by(submission_id: submission.id)

      # Log Submission
      inform('Submission', submission)

      if dry_run
        # Log Grade
        inform('Grade', grade)
        # Log PoolEntry
        inform('PoolEntry', pool_entry)
      else
        # Delete Submission
        submission&.destroy
        # Delete Grade
        inform('Grade', grade)
        grade&.destroy
        # Delete PoolEntry
        inform('PoolEntry', pool_entry)
        pool_entry&.destroy
      end
    end
  end

  def inform(title, to_be_deleted)
    amount = 1
    if to_be_deleted.respond_to? :count
      amount = to_be_deleted.count
    end
    $stdout.puts "--------#{title}: #{amount}--------"
    $stdout.puts to_be_deleted.inspect
    $stdout.puts '-------------------------'
  end
end
