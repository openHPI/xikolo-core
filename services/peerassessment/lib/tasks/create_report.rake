# frozen_string_literal: true

namespace :xikolo do
  require 'csv'

  desc <<~DESC
    Creates CSV that holds information about peer assessment participants.
  DESC

  task :create_report, [:assessment_id] => :environment do |_, args|
    assessment_id = args[:assessment_id]
    assessment = PeerAssessment.find assessment_id
    CSV.open("/tmp/peer_assessment_#{assessment.id}_report.csv", 'wb') do |csv|
      csv << [
        'UserID',
        'Team',
        'Full Name',
        'Email',
        'GradeFromPeers',
        'BonusPointsReviews',
        'BonusPointsSelfassessment',
        'BonusPointsTeamevaluation',
        'StarRating',
        'Nominations',
        'Phase',
        'Link',
      ]

      participant_statement = <<~SQL.squish
        SELECT *
        FROM participants AS p
        INNER JOIN submissions AS s ON p.user_id = s.user_id
        INNER JOIN shared_submissions AS ss ON s.shared_submission_id = ss.id
        WHERE  p.peer_assessment_id = '#{assessment_id}'
        AND ss.peer_assessment_id = '#{assessment_id}'
        AND ss.submitted = 't'
      SQL

      Participant.find_by_sql(participant_statement).each do |participant|
        shared_submission = SharedSubmission.includes(:submissions).find_by(
          submissions: {user_id: participant.user_id},
          peer_assessment_id: assessment.id
        )
        submission = shared_submission.submissions.first

        submission.grade.compute_grade
        peer_average = submission.grade.base_points.nil? ? 0 : submission.grade.base_points.round(1)

        bonus_usefulness = ''
        bonus_selfassessment = ''
        team_name = ''
        bonus_teamevaluation = ''

        # add the link to the submission
        assessment_id_short = UUID4(assessment.id).to_s(format: :base62)
        submission_id_short = UUID4(submission.id).to_s(format: :base62)
        link_to_submission = Xikolo.base_url.join(
          "peer_assessments/#{assessment_id_short}/submission_management/#{submission_id_short}"
        ).to_s

        # get Team Assessment name and points
        if assessment.is_team_assessment
          team_name = ''
          begin
            membership = Xikolo.api(:collabspace).value!
              .rel(:memberships).get(
                user_id: submission.user_id,
                status: 'admin',
                kind: 'team',
                course_id: assessment.course_id
              ).value!.first

            if membership
              team_name = membership.rel(:collab_space).get.value!['name']
            end
          rescue Restify::ClientError
            team_name = 'No Team'
          end
        end

        email = ''
        full_name = ''

        begin
          user = account_api.rel(:user).get(id: participant.user_id).value!
          email = user['email']
          full_name = user['full_name']
        rescue
          email = 'No user account'
        end

        submission.grade.bonus_points&.each do |bonus|
          bonus_usefulness = bonus[1] if bonus[0] == 'usefulness'
          bonus_selfassessment = bonus[1] if bonus[0] == 'self_assessment'

          if assessment.is_team_assessment == true && (bonus[0] == 'team_evaluation')
            bonus_teamevaluation = bonus[1]
          end
        end

        star_rating = submission.average_votes

        nominations = submission.nominations

        phase_reached = Step.find(participant.current_step).type

        csv << [
          participant.user_id,
          team_name,
          full_name,
          email,
          peer_average,
          bonus_usefulness,
          bonus_selfassessment,
          bonus_teamevaluation,
          star_rating,
          nominations,
          phase_reached,
          link_to_submission,
        ]
      rescue => e
        puts e.message
      end
    end

    $stdout.print '...finished.'
    $stdout.flush
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
