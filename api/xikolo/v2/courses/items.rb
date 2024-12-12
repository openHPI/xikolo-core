# frozen_string_literal: true

require 'uuid4'

module Xikolo
  module V2::Courses
    class Items < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'course-items'

        attribute('title') {
          description 'The item\'s title'
          type :string
        }

        attribute('position') {
          description 'The item\'s position within its section'
          type :integer
        }

        attribute('deadline') {
          description 'The date at which the item must have been finished by the user'
          type :datetime
          alias_for 'submission_deadline'
        }

        attribute('content_type') {
          description 'The type of item: one of quiz, video, rich_text, lti_exercise, peer_assessment'
          type :string
        }

        attribute('icon') {
          version max: 4
          description 'The icon for this item (reflecting the icon in the xikolo-font)'
          type :string
          reading {|item|
            case item['content_type']
              when 'quiz'
                case item['exercise_type']
                  when 'selftest'
                    'quiz'
                  when 'main'
                    'homework'
                  when 'bonus'
                    'bonus_quiz'
                  else
                    'survey'
                end
              when 'lti_exercise'
                if item['exercise_type'] == 'bonus'
                  'bonus_lti_exercise'
                else
                  'lti_exercise'
                end
              when 'peer_assessment'
                'homework'
              when 'rich_text'
                # This maps the new icon_types to the old identifiers
                icon_type_mapping = {exercise2: 'exercise', community: 'team_exercise', chat: 'discussion'}
                if item['icon_type'].present?
                  icon_type_mapping.fetch(item['icon_type'].to_sym, item['icon_type'])
                else
                  'rich_text'
                end
              else
                item['content_type']
            end
          }
        }

        attribute('icon') {
          version min: 5
          description 'The icon for this item (reflecting the icon in the xikolo-font)'
          type :string
          reading {|item|
            ItemPresenter.for(item).icon_class
          }
        }

        attribute('exercise_type') {
          description 'The rank of this exercise: one of main, bonus, selftest, survey'
          type :string
        }

        attribute('max_points') {
          description 'The number of points (with decimal) that can be achieved with this item'
          type :float
        }

        attribute('optional') {
          description 'Whether this item is optional'
          type :boolean
        }

        attribute('proctored') {
          description 'Whether this item is only accessible with proctoring if certificate was booked'
          type :boolean
        }

        attribute('accessible') {
          description 'Whether the item\'s content can be accessed at this time'
          type :boolean
          reading {|item|
            if item['effective_start_date'] && Time.zone.parse(item['effective_start_date']).future?
              next false
            end

            if item['effective_end_date'] && Time.zone.parse(item['effective_end_date']).past?
              next false
            end

            true
          }
        }

        attribute('time_effort') {
          description 'The estimated time needed to complete the item'
          type :integer
        }

        writable attribute('visited') {
          description 'Whether the current user has visited this item before'
          type :boolean
          reading {|item| !!item['user_visit'] }
        }

        includable morph_one('content') {
          foreign_type 'content_type'
          foreign_key 'content_id'

          morph 'lti_exercise', Xikolo::V2::CourseItems::LtiExercises
          morph 'quiz', Xikolo::V2::Quiz::Quizzes
          morph 'rich_text', Xikolo::V2::CourseItems::RichTexts
          morph 'video', Xikolo::V2::CourseItems::Videos
          morph 'peer_assessment', Xikolo::V2::CourseItems::PeerAssessments
        }

        has_one('section', Xikolo::V2::Courses::Sections) {
          foreign_key 'section_id'
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        link('self') {|res| "/api/v2/course-items/#{res['id']}" }
        link('html') {|res| Xikolo::V2::URL.course_item_path res['course_id'], UUID(res['id']).to_param }
      end

      filters do
        optional('section') {
          description 'Only return items belonging to the section with this UUID'
          alias_for 'section_id'
        }

        optional('course') {
          description 'Only return items belonging to the course with this UUID'
          alias_for 'course_id'
        }

        optional('content_type') {
          description 'Only return items of this content type (e.g. quiz or video)'
        }
      end

      collection do
        get 'List all items for a given course section' do
          unless filters['section_id'] || filters['course_id']
            raise Xikolo::Endpoint::Filter::InvalidFilter.new('Either a section or course filter must be provided')
          end

          course_api = Xikolo.api(:course).value!

          # set context before current_user is accessed / authenticate is called
          # required to check if time_effort is enabled
          course =
            block_access_by('id') do
              if filters['course_id']
                course_api.rel(:course).get(id: filters['course_id']).value!
              elsif filters['section_id']
                section = course_api.rel(:section).get(id: filters['section_id']).value!
                course_api.rel(:course).get(id: section['course_id']).value!
              end
            end

          in_context course['context_id']

          authenticate!

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          item_params = filters.merge(
            'all_available' => true,
            'embed' => 'user_visit',
            'user_id' => current_user.id
          )

          course_api
            .rel(:items)
            .get(item_params)
            .value!
            .map {|item| Xikolo::V2::Courses::Items.sanitize_time_effort(item, current_user) }
        end
      end

      member do
        get 'Retrieve a single item' do
          block_access_by('course_id') do
            course_api = Xikolo.api(:course).value!

            # set context before current_user is accessed / authenticate is called
            # required to check if time_effort is enabled
            item = course_api.rel(:item).get(id: UUID(id).to_s).value!
            course = course_api.rel(:course).get(id: item['course_id']).value!

            in_context course['context_id']

            authenticate!

            # Check if user has admin permissions or is enrolled to the course
            any_permission!('course.content.access', 'course.content.access.available')

            course_api
              .rel(:item)
              .get(id: UUID(id).to_s, embed: 'user_visit', user_id: current_user.id)
              .value!
              .tap {|i| Xikolo::V2::Courses::Items.sanitize_time_effort(i, current_user) }
          end
        end

        patch 'Update an item' do |entity|
          course_api = Xikolo.api(:course).value!

          # set context before current_user is accessed / authenticate is called
          # required to check if time_effort is enabled
          item = course_api.rel(:item).get(id:).value!
          course = course_api.rel(:course).get(id: item['course_id']).value!

          in_context course['context_id']

          authenticate!

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          # Allow to mark this item as visited
          if entity.to_resource['visited']
            course_api
              .rel(:item_user_visit).post(
                {},
                {
                  user_id: current_user.id,
                  item_id: id,
                }
              ).value!
          end

          course_api
            .rel(:item)
            .get(id:, embed: 'user_visit', user_id: current_user.id)
            .value!
            .tap {|i| Xikolo::V2::Courses::Items.sanitize_time_effort(i, current_user) }
        end
      end

      def self.sanitize_time_effort(item, user)
        item.tap {|i| i['time_effort'] = 0 unless user.feature?('time_effort') }
      end
    end
  end
end
