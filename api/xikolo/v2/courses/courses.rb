# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class Courses < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'courses'

        attribute('title') {
          description 'The course name'
          type :string
        }

        attribute('slug') {
          description 'A short name for use in URLs etc.'
          alias_for 'course_code'
          type :string
        }

        attribute('start_at') {
          description 'Date and time when this course starts'
          type :datetime
          alias_for 'start_date'
        }

        attribute('end_at') {
          description 'Date and time when this course ends'
          type :datetime
          alias_for 'end_date'
        }

        attribute('abstract') {
          description 'A short text describing the course contents'
          type :string
        }

        member_only attribute('description') {
          description 'A long-form text describing the course contents in greater detail'
          type :string
        }

        attribute('image_url') {
          description 'URL to the course image'
          type :string
          reading {|course|
            visual = ::Course::Visual.find_by(course_id: course['id'])
            url = visual&.image_url || Xikolo::V2::URL.asset_url('defaults/course.png')

            Imagecrop.transform(url)
          }
        }

        attribute('images') {
          description 'URLs to the course image in various sizes, with the exact dimensions of each image. \
                       Clients can use these for loading the optimal size of an image depending on the viewport size.'
          type :array, of: nested_type(:hash, of: {
            max_width: :integer,
            max_height: :integer,
            url: :string,
          })

          reading {|course|
            visual = ::Course::Visual.find_by(course_id: course['id'])
            url = visual&.image_url || Xikolo::V2::URL.asset_url('defaults/course.png')

            [100, 200, 300, 400, 500, 600, 700].map do |max_height|
              max_width = max_height * 2

              {
                max_width:,
                max_height:,
                url: Imagecrop.transform(url, width: max_width, height: max_height),
              }
            end
          }
        }

        attribute('language') {
          description 'The language in which the course will be held'
          type :string
        }

        attribute('status') {
          description 'Current state of the course: one of external, preparation, announced, preview, active or self-paced'
          alias_for 'state'
          type :string
        }

        attribute('classifiers') {
          description 'A hash of classifiers for this course (used for categorization), mapping from names to arrays of assigned groups in these categories.'
          type :hash
        }

        attribute('teachers') {
          description 'A string, listing the names of teachers or a short title for the teaching team'
          type :string
        }

        attribute('accessible') {
          description 'Whether the course content is already accessible'
          type :boolean
        }

        attribute('enrollable') {
          description 'Whether any user can enroll in this course'
          type :boolean
          reading {|course| course.rel?(:enrollments) }
        }

        attribute('hidden') {
          description 'Whether this course is hidden (i.e. not visible to guests and regular users)'
          type :boolean
        }

        attribute('external') {
          description 'Whether this course is hosted on an external platform'
          type :boolean
          reading {|course| course['external_course_url'].present? }
        }

        attribute('external_url') {
          description 'URL to the external course, if it is hosted on another platform'
          type :string
          alias_for 'external_course_url'
        }

        attribute('policy_url') {
          description 'URL to a document detailing any policies that the user has to agree to before enrolling'
          type :string
          reading {|course|
            next unless course['policy_url'].respond_to? :key

            locales = [
              I18n.locale.to_s,
              Xikolo.config.locales['default'],
              *Xikolo.config.locales['available'],
            ]

            locale = locales.find {|l| course['policy_url'].key? l }
            locale && course['policy_url'][locale]
          }
        }

        attribute('certificates') {
          description 'A hash with information about the certificates that can be gained in this course.'

          type :hash, of: {
            confirmation_of_participation: nested_type(:hash, of: {
              available: :boolean,
              threshold: :integer,
            }),
            record_of_achievement: nested_type(:hash, of: {
              available: :boolean,
              threshold: :integer,
            }),
            qualified_certificate: nested_type(:hash, of: {
              available: :boolean,
            }),
          }

          reading {|course|
            {
              confirmation_of_participation: {
                available: course['cop_enabled'],
                threshold: course['cop_threshold_percentage'],
              },
              record_of_achievement: {
                available: course['roa_enabled'],
                threshold: course['roa_threshold_percentage'],
              },
              qualified_certificate: {
                available: course['proctored'],
              },
            }
          }
        }

        attribute('on_demand') {
          description 'Whether this course is available for on_demand/reactivation option'
          type :boolean
        }

        attribute('learning_goals') {
          description 'What the learner is expected to gain from the course'
          type :array, of: :string
        }

        attribute('target_groups') {
          description 'The groups at which the course is targeted'
          type :array, of: :string
        }

        attribute('show_on_list') {
          description 'Whether this course should be shown on the course list'
          type :boolean
        }

        member_only attribute('teaser_stream') {
          description 'Media info about the teaser stream, if it exists'
          type :hash, of: Xikolo::V2::VideoStream.schema
          reading {|course|
            visual = ::Course::Visual.find_by(course_id: course['id'])
            next if visual&.video_stream.blank?

            Xikolo::V2::VideoStream.data visual.video_stream
          }
        }

        includable has_one('channel', Xikolo::V2::Courses::Channels) {
          foreign_key 'channel_code'
        }

        includable has_one('user_enrollment', Xikolo::V2::Courses::Enrollments) {
          embedded {|res|
            next nil if res['enrollment'].nil?

            # Ensure the enrollment hash has all the data that's needed for
            # relationship decoration
            res['enrollment'].merge('course_id' => res['id'])
          }
        }

        includable has_many('sections', Xikolo::V2::Courses::Sections) {
          filter_by 'course'
        }

        has_many('documents', Xikolo::V2::Documents::Documents) {
          filter_by 'course'
        }

        has_one('progress', Xikolo::V2::Courses::CourseProgresses) {
          foreign_key 'id'
        }

        has_one('last_visit', Xikolo::V2::Courses::LastVisits) {
          foreign_key 'id'
        }

        has_many('dates', Xikolo::V2::Courses::Dates) {
          filter_by 'course'
        }

        has_many('repetition_suggestions', Xikolo::V2::Courses::RepetitionSuggestions) {
          filter_by 'course'
        }

        link('self') {|course| "/api/v2/courses/#{course['id']}" }
      end

      filters do
        optional('channel') {
          description 'Only return courses belonging to the channel with this UUID'
        }
        optional('document') {
          description 'Only return courses belonging to the document with this UUID'
          alias_for 'document_id'
        }
      end

      paginate! per_page: 500

      collection do
        get 'List all courses' do
          # TODO: Cache-Control: no-cache
          block_courses_by('id') do
            Xikolo.api(:course).value!.rel(:api_v2_course_courses).get(
              filters.merge({'embed' => 'enrollment'}),
              headers: {'Authorization' => auth_header}
            ).value!
          end
        end
      end

      member do
        get 'Get information about a course' do
          block_access_by('id') do
            Xikolo.api(:course).value!.rel(:api_v2_course_course).get(
              {id:, embed: 'description,enrollment'},
              headers: {'Authorization' => auth_header}
            ).value!
          end
        end
      end
    end
  end
end
