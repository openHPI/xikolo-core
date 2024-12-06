# frozen_string_literal: true

class MigrateCourseAttributesToCourseVisual < ActiveRecord::Migration[6.0]
  module Video
    class Video < ActiveRecord::Base; end
  end

  module Course
    class Course < ActiveRecord::Base
      has_one :visual,
        class_name: 'CourseVisual',
        dependent: :destroy
    end

    class CourseVisual < ActiveRecord::Base
      belongs_to :course, class_name: 'Course'
    end
  end

  def change
    reversible do |dir|
      dir.up do
        courses = Course::Course.where.not(visual_uri: nil).or(Course::Course.where.not(vimeo_id: nil))
        begin
          courses.find_each(batch_size: 50) do |course|
            course_visual = course.build_visual
            course_visual.image_uri = course.visual_uri if course.visual_uri
            if course.vimeo_id.present?
              video = Video::Video.create!(pip_stream_id: course.vimeo_id)
              course_visual.video_id = video.id
            end
            course_visual.save
          end
        rescue ActiveRecord::RecordInvalid
          # noop
        end
      end
    end
  end
end
