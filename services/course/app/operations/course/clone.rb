# frozen_string_literal: true

class Course::Clone < ApplicationOperation
  def initialize(old_course_id, new_course_code)
    super()
    @old_course = Course.by_identifier(old_course_id).take!
    @new_course_code = new_course_code

    @quiz_api = Xikolo.api(:quiz).value!

    @section_id_map = {}
  end

  def call
    target_course.tap do |course|
      Course::Visual::Clone.call(@old_course.visual, course)

      # Clone course sections and items, starting with the parent sections
      # (parent_id NULL comes first with DESC).
      @old_course.sections.unscope(:order)
        .order(parent_id: :desc, position: :asc)
        .each do |old_section|
        new_section = clone_section(old_section, course:)
        old_section.items.each do |item|
          clone_item(item, new_section)
        end
      end
    end
  end

  private

  def target_course
    Course.by_identifier(@new_course_code).take.presence ||
      Course::Create.call(
        @old_course.attributes.except(
          'id', 'created_at', 'updated_at',
          'start_date', 'end_date', 'display_start_date', 'middle_of_course',
          'rating_votes', 'rating_stars'
        ).tap do |attrs|
          attrs['course_code'] = @new_course_code
          attrs['status'] = 'preparation'
          attrs['special_groups'] = []
          attrs['records_released'] = false
          attrs['description'] = 'Placeholder (will be updated later)'
          attrs['proctored'] = false
        end
      ).tap do |course|
        course.update \
          description: clone_file_references(@old_course.description, course_id: course.id),
          stage_visual_uri: copy_file(@old_course.stage_visual_uri, course_id: course.id)
      end
  end

  def clone_section(old_section, course:)
    Section.new(
      old_section.attributes.except('id', 'start_date', 'end_date')
    ).tap do |s|
      s.course_id = course.id
      if s.parent_id
        # Update `parent_id` to reference the cloned parent section.
        s.parent_id = @section_id_map[old_section.parent_id]
      end
      s.save!

      # Build section ID mapping to be able to update `parent_id` references.
      @section_id_map[old_section.id] = s.id
    end
  end

  def clone_item(old_item, new_section)
    Item.new(
      old_item.attributes
        .except('id', 'start_date', 'end_date', 'submission_deadline')
        .then do |attrs|
          # Do not set the time effort, i.e. assume that the time effort has been
          # overwritten, for cloned video items. For now, the time effort should
          # always be determined based on the corresponding stream.
          # This is a short-term fix until the overwritten status can be checked in
          # the database directly in the monolithic application (and not via Restify).
          attrs = attrs.except('time_effort') if old_item.content_type == 'video'
          attrs['proctored'] = false
          attrs
        end
    ).tap do |i|
      i.section_id = new_section.id
      i.original_item_id = old_item.id

      new_content = clone_content(old_item, course_id: new_section.course_id)
      # Do not save the item when the content cannot be cloned.
      next unless new_content

      i.content_id = new_content[:id]
      i.save!
    end
  end

  def clone_content(old_item, course_id:)
    rel = case old_item.content_type
            when 'rich_text'
              return Richtext.create! \
                course_id:,
                text: clone_file_references(Richtext.find(old_item.content_id).text, course_id:)
            when 'video'
              return Video::Clone.call(Duplicated::Video.find(old_item.content_id))
            when 'quiz'
              @quiz_api.rel(:quiz)
            when 'lti_exercise'
              return LtiExercise::Clone.call(
                Duplicated::LtiExercise.find(old_item.content_id),
                course_id
              )
          end
    return unless rel

    content = rel.get(id: old_item.content_id).value
    return unless content&.rel? :clone

    content.rel(:clone).post(course_id:).value
  rescue ActiveRecord::RecordNotFound # Richtext not found
    nil
  end

  def clone_file_references(markup, course_id:)
    @file_cache ||= {} # Clone a file only (even with multiple references)
    markup.gsub(Xikolo::S3.url_regex) do |match|
      next @file_cache[match] if @file_cache.key? match

      @file_cache[match] = copy_file(match, course_id:)
    end
  end

  def copy_file(uri, course_id:)
    return unless uri

    original = Xikolo::S3.object(uri)
    # Replace course ID in key
    key = original.key.split('/').tap do |parts|
      parts[1] = UUID4(course_id).to_s(format: :base62)
    end.join('/')

    Xikolo::S3.copy_to(original, target: key, bucket: :course, acl: 'public-read')
  rescue Aws::S3::Errors::ServiceError
    # Do not fail if the file cannot be copied.
  end
end
