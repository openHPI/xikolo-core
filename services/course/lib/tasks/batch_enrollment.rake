# frozen_string_literal: true

# rubocop:disable Layout/LineLength
namespace :users_csv do
  require 'csv'

  desc 'takes csv file containing users email addresses, returns csv file with email addresses and user ids. Pass the filename using CSV=/path/to/file.csv'

  task get_users: :environment do
    csv_input = CSV.read(ENV.fetch('CSV', nil))
    known_emails = []
    unknown_emails = []

    csv_input.each do |row|
      email = row[0]
      account_service = Xikolo.api(:account).value!

      begin
        response = account_service.rel(:email).get({id: email}).value!
        known_emails << {
          user_id: response.fetch('user_id'),
          address: response.fetch('address'),
        }
      rescue Restify::NotFound
        unknown_emails << email
      end
    end

    if unknown_emails.any?
      puts '--------------------------------------'
      puts 'Users not found:'
      puts '--------------------------------------'
      unknown_emails.each do |email|
        puts email
      end
    end

    CSV.open('/tmp/users.csv', 'w') do |csv_output|
      csv_output << ['User ID', 'Email']
      puts '--------------------------------------'
      puts 'Users added to tmp/users.csv file:'
      puts '--------------------------------------'

      known_emails.each do |email|
        csv_output << [email[:user_id], email[:address]]
        puts email[:address]
      end

      puts '--------------------------------------'
      puts 'To create the enrollments run:'
      puts '--------------------------------------'
      puts 'xikolo-course rake users_csv:enroll_users CSV=/tmp/users.csv COURSE={course_id}'
    end
  end

  desc 'enrolls users from csv file to a course given by course ID or code'
  task enroll_users: :environment do
    account_service = Xikolo.api(:account).value!
    course = Course.by_identifier(ENV.fetch('COURSE', nil)).take!
    users_failed = []

    csv_table = CSV.read(ENV.fetch('CSV', nil), headers: true)

    csv_table.each do |row|
      begin
        user = account_service.rel(:user).get({id: row['User ID']}).value!
      rescue Restify::NotFound
        users_failed << row.to_a
        puts "User #{row.to_a} could not be found."
        next
      end

      # Ensure the user account has been confirmed.
      unless user.fetch('confirmed')
        users_failed << row.to_a
        puts "User #{row.to_a} has not yet been confirmed."
        next
      end

      enrollment = Enrollment::Create.call(user.fetch('id'), course)

      if enrollment.persisted?
        puts "Enrolled user #{row.to_a} to course #{course.course_code}."
      else
        users_failed << row.to_a
      end
    end

    puts '------------------------------------------------------------'

    users_failed.each do |row|
      puts "Failed to enroll user #{row.to_a}"
    end
  end
end
# rubocop:enable all
