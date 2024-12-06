# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock
namespace :xikolo do
  require 'csv'

  desc <<~DESC
    Writes all email addresses of participants that qualified for a grade to a CSV file.
    Expects PeerAssessmentID [PA_ID] as parameter.
  DESC

  pa_id = ENV.fetch('PA_ID', nil)

  PARTICIPANT_STATEMENT = <<~SQL.squish
    SELECT * FROM participants JOIN submissions USING (peer_assessment_id, user_id)
    WHERE peer_assessment_id = '#{pa_id}'
    AND submitted = 't';
  SQL

  task email_csv: :environment do
    $stdout.print "Export started \n"

    CSV.open("/tmp/peer_assessment_#{pa_id}_mails.csv", 'wb') do |csv|
      csv << ['e-mail']
      $stdout.print '.'
      participants_with_submissions.each do |participant|
        next unless ENV.fetch('ALL', nil) || participant.can_receive_grade?

        begin
          user = account_api.rel(:user).get(id: participant.user_id).value!
          csv << [user['email']]
        rescue
          puts "No user account retrieved for ID '#{participant.user_id}'"
        end
      end

      $stdout.print '...finished.'
      $stdout.flush
    end
  end

  def participants_with_submissions
    Participant.find_by_sql(PARTICIPANT_STATEMENT)
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
# rubocop:enable all
