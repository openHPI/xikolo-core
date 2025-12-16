# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Prerequisite Status: Index', type: :request do
  subject(:index) do
    api.rel(:course).get({id: course.course_code}).value!
      .rel(:prerequisite_status).get({user_id:}).value!
  end

  let(:api) { Restify.new(course_service.root_url).get.value! }
  let(:course) { create(:'course_service/course') }
  let(:user_id) { generate(:user_id) }

  context 'for a course without prerequisites' do
    it 'returns a simple representation' do
      expect(index).to respond_with :ok
      expect(index.to_h).to eq(
        'fulfilled' => true,
        'prerequisites' => []
      )
    end

    it 'does not schedule assigning the user to the course students group' do
      expect do
        index
      end.not_to change(CourseService::EnrollmentGroupWorker.jobs, :size)
    end
  end

  context 'for a course with multiple prerequisites' do
    let(:roa_course) { create(:'course_service/course', :archived, start_date: 4.months.ago, records_released: true, roa_enabled: true) }
    let(:cop_course) { create(:'course_service/course', :archived, start_date: 5.months.ago, records_released: true, cop_enabled: true) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      roa_requirement = create(:'course_service/course_set')
      roa_requirement.courses << roa_course

      create(:'course_service/course_set_relation', source_set: track, target_set: roa_requirement, kind: 'requires_roa')

      cop_requirement = create(:'course_service/course_set')
      cop_requirement.courses << cop_course

      create(:'course_service/course_set_relation', source_set: track, target_set: cop_requirement, kind: 'requires_cop')

      # CoP requirement is fulfilled
      cop_item = create(:'course_service/item', section: create(:'course_service/section', course: cop_course))
      create(:'course_service/enrollment', course: cop_course, user_id:)
      create(:'course_service/visit', item: cop_item, user_id:)

      # Visual
      roa_course.create_visual!(image_uri: "s3://xikolo-public/courses/#{roa_course.id}/encodedUUUID/visual.jpg")
      cop_course.create_visual!(image_uri: "s3://xikolo-public/courses/#{cop_course.id}/anotherEncodedUUUID/visual.jpg")
    end

    it 'returns the complete status representation' do
      expect(index).to respond_with :ok
      expect(index.to_h).to eq(
        'fulfilled' => false,
        'prerequisites' => [
          {
            'course' => {
              'id' => cop_course.id,
              'course_code' => cop_course.course_code,
              'title' => cop_course.title,
              'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{cop_course.id}/anotherEncodedUUUID/visual.jpg",
            },
            'fulfilled' => true,
            'free_reactivation' => false,
            'required_certificate' => 'cop',
            'score' => true,
          },
          {
            'course' => {
              'id' => roa_course.id,
              'course_code' => roa_course.course_code,
              'title' => roa_course.title,
              'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{roa_course.id}/encodedUUUID/visual.jpg",
            },
            'fulfilled' => false,
            'free_reactivation' => true,
            'required_certificate' => 'roa',
            'score' => nil,
          },
        ]
      )
    end

    it 'does not schedule assigning the user to the course students group' do
      expect do
        index
      end.not_to change(CourseService::EnrollmentGroupWorker.jobs, :size)
    end

    context 'when all the requirements are met' do
      before do
        # Ensure the RoA course is completed as well
        roa_item = create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: roa_course))
        create(:'course_service/enrollment', course: roa_course, user_id:)
        create(:'course_service/result', item: roa_item, user_id:, dpoints: 8)
      end

      context 'and the user is enrolled in the track' do
        before { create(:'course_service/enrollment', course:, user_id:) }

        it 'responds with completely fulfilled prerequisites' do
          expect(index).to respond_with :ok
          expect(index.to_h).to eq(
            'fulfilled' => true,
            'prerequisites' => [
              {
                'course' => {
                  'id' => cop_course.id,
                  'course_code' => cop_course.course_code,
                  'title' => cop_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{cop_course.id}/anotherEncodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'cop',
                'score' => true,
              },
              {
                'course' => {
                  'id' => roa_course.id,
                  'course_code' => roa_course.course_code,
                  'title' => roa_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{roa_course.id}/encodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'roa',
                'score' => '80.0',
              },
            ]
          )
        end

        it 'schedules assigning the user to the course students group' do
          expect do
            index
          end.to change(CourseService::EnrollmentGroupWorker.jobs, :size).from(0).to(1)
        end

        it '(asynchronously) assigns the user to the course students group' do
          assignment = Stub.request(
            :account, :post, '/memberships',
            body: {
              group: "course.#{course.course_code}.students",
              user: user_id,
            }
          ).to_return Stub.response(status: 201)

          Sidekiq::Testing.inline! { index }

          expect(assignment).to have_been_requested
        end
      end

      context 'but the user is not enrolled in the track' do
        it 'responds with completely fulfilled prerequisites' do
          expect(index).to respond_with :ok
          expect(index.to_h).to eq(
            'fulfilled' => true,
            'prerequisites' => [
              {
                'course' => {
                  'id' => cop_course.id,
                  'course_code' => cop_course.course_code,
                  'title' => cop_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{cop_course.id}/anotherEncodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'cop',
                'score' => true,
              },
              {
                'course' => {
                  'id' => roa_course.id,
                  'course_code' => roa_course.course_code,
                  'title' => roa_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{roa_course.id}/encodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'roa',
                'score' => '80.0',
              },
            ]
          )
        end

        it '(asynchronously) does not assign the user to the course students group' do
          assignment = Stub.request(
            :account, :post, '/memberships',
            body: {
              group: "course.#{course.course_code}.students",
              user: user_id,
            }
          ).to_return Stub.response(status: 201)

          Sidekiq::Testing.inline! { index }

          expect(assignment).not_to have_been_requested
        end
      end

      context 'but the user has un-enrolled from the track' do
        before { create(:'course_service/enrollment', course:, user_id:, deleted: true) }

        it 'responds with completely fulfilled prerequisites' do
          expect(index).to respond_with :ok
          expect(index.to_h).to eq(
            'fulfilled' => true,
            'prerequisites' => [
              {
                'course' => {
                  'id' => cop_course.id,
                  'course_code' => cop_course.course_code,
                  'title' => cop_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{cop_course.id}/anotherEncodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'cop',
                'score' => true,
              },
              {
                'course' => {
                  'id' => roa_course.id,
                  'course_code' => roa_course.course_code,
                  'title' => roa_course.title,
                  'visual_url' => "https://s3.xikolo.de/xikolo-public/courses/#{roa_course.id}/encodedUUUID/visual.jpg",
                },
                'fulfilled' => true,
                'free_reactivation' => false,
                'required_certificate' => 'roa',
                'score' => '80.0',
              },
            ]
          )
        end

        it '(asynchronously) does not assign the user to the course students group' do
          assignment = Stub.request(
            :account, :post, '/memberships',
            body: {
              group: "course.#{course.course_code}.students",
              user: user_id,
            }
          ).to_return Stub.response(status: 201)

          Sidekiq::Testing.inline! { index }

          expect(assignment).not_to have_been_requested
        end
      end
    end
  end
end
