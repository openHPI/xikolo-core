# frozen_string_literal: true

# This class represents the context in which a topic was posted,
# and all information associated to it. This can be things like
# courses, sections (course weeks) and collab spaces.
#
# Depending on the type of context, the base class instantiates a
# subclass that implements certain checks, such as whether the
# context still allows posting, correctly for that context.
class TopicContext
  class << self
    # Return a context object for the given topic.
    #
    # This can be established depending on the presence of certain implicit
    # tags. Based on these tags, the corresponding resources in other services
    # can be asked e.g. whether their forum is still open.
    def for(topic)
      section_tags = topic.tags.select do |tag|
        tag.type == 'ImplicitTag' && tag.referenced_resource == 'Xikolo::Course::Section'
      end

      if section_tags.any?
        CombinedTopicContext.new(
          CourseTopicContext.new(topic.course_id),
          *section_tags.map do |tag|
            SectionTopicContext.new(tag.name)
          end
        )
      else
        CourseTopicContext.new(topic.course_id)
      end
    end

    # Connect (and create, if necessary) the corresponding implicit tags for
    # the topic's context, and return that context.
    def establish!(topic, section_id: nil, item_id: nil)
      if item_id
        section_id = Xikolo.api(:course).value!.rel(:item).get({id: item_id}).value!['section_id']

        begin
          topic.implicit_tags = [
            ImplicitTag.find_or_create_by!(
              name: item_id, referenced_resource: 'Xikolo::Course::Item', course_id: topic.course_id
            ),
            ImplicitTag.find_or_create_by!(
              name: section_id, referenced_resource: 'Xikolo::Course::Section', course_id: topic.course_id
            ),
          ]
        rescue ActiveRecord::RecordNotUnique
          retry
        end

        CombinedTopicContext.new(
          CourseTopicContext.new(topic.course_id),
          SectionTopicContext.new(section_id)
        )
      end
    end
  end

  class CourseTopicContext
    def initialize(course_id)
      @course_id = course_id
    end

    def open?
      !course['forum_is_locked']
    end

    private

    def course
      @course ||= Xikolo.api(:course).value!.rel(:course).get({id: @course_id}).value!
    end
  end

  class SectionTopicContext
    def initialize(section_id)
      @section_id = section_id
    end

    def open?
      !section['pinboard_closed']
    end

    private

    def section
      @section ||= Xikolo.api(:course).value!.rel(:section).get({id: @section_id}).value!
    end
  end

  class CombinedTopicContext
    def initialize(*contexts)
      @wrapped = contexts
    end

    def open?
      @wrapped.all?(&:open?)
    end
  end
end
