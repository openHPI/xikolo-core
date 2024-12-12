# frozen_string_literal: true

module Bridges
  module Transpipe
    class CoursesController < BaseController
      before_action Xi::Controllers::RequireBearerToken.new(
        realm: Transpipe.realm,
        token: -> { Transpipe.shared_secret }
      )

      def index
        response.link(bridges_transpipe_courses_url(page: page + 1), rel: 'next') if courses.rel?(:next)
        response.link(bridges_transpipe_courses_url(page: page - 1), rel: 'prev') if courses.rel?(:prev)

        render json: courses.map {|course| serialize_course_for_index(course) }
      end

      def show
        return head(:not_found, content_type: 'text/plain') if external_course?

        render json: serialize_course_for_show(course)
      rescue Restify::NotFound
        head(:not_found, content_type: 'text/plain')
      end

      private

      def courses
        @courses ||= course_api.rel(:courses)
          .get(exclude_external: true, latest_first: true, page:)
          .value!
      end

      def page
        @page ||= [params[:page].to_i, 1].max
      end

      def course
        @course ||= course_api.rel(:course).get(id: params[:id]).value!
      end

      def sections
        @sections ||= course_api.rel(:sections).get(course_id: params[:id]).value!
      end

      def videos
        @videos ||= course_api.rel(:items).get(course_id: params[:id], content_type: 'video').value!
      end

      def teachers
        @teachers ||= course_api.rel(:teachers).get(course: params[:id]).value!
      end

      def external_course?
        course['external_course_url'].present?
      end

      def serialize_course_for_index(course)
        {
          id: course['id'],
          title: course['title'],
          abstract: course['abstract'],
          language: course['lang'],
          'start-date' => course['start_date'],
          'end-date' => course['end_date'],
          status: course['status'],
        }
      end

      def serialize_course_for_show(course)
        additional_values = {
          sections: sections.map {|section| serialize_section(section) },
          teachers: teachers.map {|teacher| serialize_teacher(teacher) },
          alternative_teacher_text: course['alternative_teacher_text'],
        }
        serialize_course_for_index(course).merge(additional_values)
      end

      def serialize_section(section)
        {
          id: section['id'],
          title: section['title'],
          accessible: accessible?(section),
          'start-date' => section['start_date'],
          videos: videos.select {|video| video['section_id'] == section['id'] }
            .map {|video| serialize_video(video) },
        }
      end

      def serialize_video(video)
        {
          id: video['content_id'],
          'item-id': video['id'],
          title: video['title'],
          accessible: accessible?(video),
          'start-date' => video['start_date'],
        }
      end

      def serialize_teacher(teacher)
        {
          id: teacher['id'],
          name: teacher['name'],
        }
      end

      def accessible?(resource)
        (resource['start_date'].nil? || Time.zone.parse(resource['start_date']) <= Time.zone.now) &&
          (resource['end_date'].nil? || Time.zone.parse(resource['end_date']) >= Time.zone.now) &&
          resource['published'] == true
      end
    end
  end
end
