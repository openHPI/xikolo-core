# frozen_string_literal: true

module Course
  module Structure
    class Node < ::ApplicationRecord
      # Map "type" column values to concrete subclasses.
      # NOTE: This can be used to map obsolete values to newer classes, or when
      # renaming models.
      STI_TYPE_TO_CLASS = {
        'branch' => '::Course::Structure::Branch',
        'fork' => '::Course::Structure::Fork',
        'item' => '::Course::Structure::Item',
        'root' => '::Course::Structure::Root',
        'section' => '::Course::Structure::Section',
      }.freeze

      # What "type" should be used when storing each subclass?
      STI_CLASS_TO_TYPE = {
        'Course::Structure::Branch' => 'branch',
        'Course::Structure::Fork' => 'fork',
        'Course::Structure::Item' => 'item',
        'Course::Structure::Root' => 'root',
        'Course::Structure::Section' => 'section',
      }.freeze

      acts_as_nested_set(
        scope: :course_id,
        counter_cache: :children_count,
        dependent: :destroy,
        touch: true
      )

      belongs_to :course, class_name: '::Course::Course'

      class << self
        ##
        # Resolve the concrete subclass to use for a value of the type column.
        #
        # This overrides ActiveRecord::Inheritance::ClassMethods#find_sti_class.
        def find_sti_class(type_name)
          if (cls = STI_TYPE_TO_CLASS[type_name])
            cls.constantize
          else
            raise SubclassNotFound.new("Unsupported node type: #{type_name}")
          end
        end

        ##
        # Determine the type identifier to use as "type" when storing a concrete subclass.
        #
        # This overrides ActiveRecord::Inheritance::ClassMethods#sti_name.
        def sti_name
          STI_CLASS_TO_TYPE.fetch(name)
        end
      end

      def needs_recalculation?
        return true if course.progress_calculated_at.nil?
        return false if progress_stale_at.nil?

        progress_stale_at > course.progress_calculated_at
      end
    end
  end
end
