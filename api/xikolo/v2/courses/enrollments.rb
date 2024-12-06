# frozen_string_literal: true

class SmowlConfirmation
  def self.passed?(enrollment)
    course = Course::Course.where(deleted: false).find(enrollment['course_id'])
    Proctoring::SmowlAdapter.new(course).passed?(
      Struct.new(:id).new(enrollment['user_id'])
    )
  end
end

module Xikolo
  module V2::Courses
    class Enrollments < Xikolo::Endpoint::CollectionEndpoint
      CERTIFICATE_TYPE_URL_MAPPING = {
        'confirmation_of_participation' => ::Certificate::Record::COP,
        'record_of_achievement' => ::Certificate::Record::ROA,
        'qualified_certificate' => ::Certificate::Record::CERT,
      }.freeze

      entity do
        type 'enrollments'

        attribute('certificates') {
          description 'A hash with information about the achieved certificates (confirmation_of_participation, record_of_achievement, qualified_certificate): Every value is either a URL pointing to the certificate file, or null'
          type :hash, of: {
            confirmation_of_participation: :string,
            record_of_achievement: :string,
            qualified_certificate: :string,
          }
          reading {|enrollment|
            enrollment['certificates'].tap {|hash|
              hash['qualified_certificate'] = hash.delete('certificate') && SmowlConfirmation.passed?(enrollment)
            }.to_h {|type, available|
              url = if available
                      Xikolo::V2::URL.certificate_render_url(
                        course_id: enrollment['course_id'],
                        type: CERTIFICATE_TYPE_URL_MAPPING[type]
                      )
                    end
              [type, url]
            }
          }
        }

        writable attribute('completed') {
          description 'Whether or not the user completed this course'
          type :boolean
        }

        attribute('reactivated') {
          description 'Whether this enrollment has an active course reactivation, i.e. when the user has paid for taking the full course, with homework and exam, after the regular course time has ended'
          type :boolean
        }

        attribute('proctored') {
          description 'Whether the user booked a certificate for this course'
          type :boolean
        }

        attribute('created_at') {
          description 'The date and time when this enrollment was created'
          type :datetime
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        has_one('progress', Xikolo::V2::Courses::CourseProgresses) {
          foreign_key 'course_id'
        }

        link('self') {|enrollment| "/api/v2/enrollments/#{enrollment['id']}" }
      end

      member do
        get 'Get the enrollment' do
          enrollment = Xikolo.api(:course).value!.rel(:enrollments).get(
            id:,
            learning_evaluation: true
          ).value!.first

          authenticate_as! enrollment['user_id']

          enrollment
        end

        patch 'Update the enrollment' do |entity|
          old_enrollment = Xikolo.api(:course).value!.rel(:enrollment).get(id:).value!

          # Check that only users can update their own enrollments
          authenticate_as! old_enrollment['user_id']

          # Update the enrollment with new values...
          Xikolo.api(:course).value!.rel(:enrollment).patch(
            entity.to_resource,
            id:
          ).value!

          # ...and return the updated enrollment!
          # We use the enrollments index route here (and return the first result), because without it, we cannot
          # get any learning evaluation data (which we need for some of the attributes).
          Xikolo.api(:course).value!.rel(:enrollments).get(
            course_id: old_enrollment['course_id'],
            user_id: old_enrollment['user_id'],
            learning_evaluation: true
          ).value!.first
        end

        delete 'Delete the enrollment' do
          enrollment = Xikolo.api(:course).value!.rel(:enrollment).get(id:).value!

          authenticate_as! enrollment['user_id']

          Xikolo.api(:course).value!.rel(:enrollment).delete(id:).value!
        end
      end

      collection do
        get 'List all enrollments' do
          authenticate!

          block_courses_by('course_id') do
            Xikolo.api(:course).value!.rel(:enrollments).get(
              user_id: current_user.id,
              learning_evaluation: true
            ).value!
          end
        end

        post 'Create enrollments' do |entity|
          authenticate!

          course_api = Xikolo.api(:course).value!
          course = course_api.rel(:course).get(id: entity.to_resource['course_id']).value!
          forbidden! if course['invite_only']

          # Create the new enrollment...
          new_enrollment = course_api.rel(:enrollments).post(
            user_id: current_user.id,
            course_id: entity.to_resource['course_id']
          ).value!

          # ...and return the created enrollment!
          # We use the enrollments index route here (and return the first result), because without it, we cannot
          # get any learning evaluation data (which we need for some of the attributes).
          course_api.rel(:enrollments).get(
            course_id: new_enrollment['course_id'],
            user_id: new_enrollment['user_id'],
            learning_evaluation: true
          ).value!.first
        end
      end
    end
  end
end
