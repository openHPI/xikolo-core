# frozen_string_literal: true

module Navigation
  class TableOfContents < ApplicationComponent
    renders_many :sections, Navigation::Section

    class << self
      def for_course(...)
        CourseToc.new(...).build
      end
    end

    class CourseToc
      def initialize(user:, course:, sections:, current_section:, current_item:, context:)
        @user = user
        @course = course
        @sections = sections
        @current_section = current_section
        @current_item = current_item
        @context = context
      end

      def build
        ::Navigation::TableOfContents.new.tap do |toc|
          # 2. Add all public (visible) sections, including alternative sections.
          published_sections.each do |section|
            SectionToc.new(context: self, course: @course, section:)
              .build { toc.with_section(**it) }

            next unless section.section_choices?

            section.section_choices.each do |alternative|
              SectionToc.new(context: self, course: @course, section: SectionPresenter.new(section: alternative))
                .build { toc.with_section(**it) }
            end
          end
        end
      end

      def active_section?(section)
        !@current_section.nil? && (@current_section['id'] == section.id)
      end

      def active_item?(item)
        @current_item.present? && @current_item['id'] == item.id
      end

      def course_accessible?
        @user.allowed?('course.content.access')
      end

      def content_available?
        @user.allowed?('course.content.access.available')
      end

      def items_for(section)
        items_by_section.fetch(section.id.to_s, [])
      end

      def user_progress?
        @user.logged_in?
      end

      def user_id
        @user.id
      end

      # A reactivated enrollment postpones the quizzes' submission deadlines.
      def enrollment
        return @enrollment if defined?(@enrollment)

        @enrollment = (CourseService::Enrollment.find_by(course_id: @course.id, user_id: @user.id) if @user.logged_in?)
      end

      private

      # Load the items of all sections at once, as every section can be expanded.
      def items_by_section
        @items_by_section ||= begin
          items = @course.items
            .where(published: true)
            .includes(section: :course) # to check the effective dates
          # Order within each section, as the sections are already ordered.
          # Courses with a content tree are ordered by their nodes, not the item
          # positions, and only show the content test branches of the user.
          items = if @course.legacy?
                    items.reorder(:position)
                  # Users with access to all content see the items of all branches.
                  elsif course_accessible?
                    items.joins(:node).reorder('nodes.lft ASC')
                  else
                    CourseService::Structure::UserItemsSelector.new(@course.node, @user.id).items(scope: items)
                  end
          # Include the user's visits and results to mark the completed items.
          items = items.user_state(@user.id) if user_progress?
          items.group_by(&:section_id)
        end
      end

      def published_sections
        @sections.filter_map do |section|
          SectionPresenter.new(section:, user: @user) if section.published?
        end
      end

      class SectionToc
        include Rails.application.routes.url_helpers

        def initialize(context:, course:, section:)
          @context = context
          @course = course
          @section = section
        end

        def build
          yield({
            text: @section.title,
            link: ({href: course_section_path(@course.course_code, @section)} if accessible?),
            active: @context.active_section?(@section),
            locked: !@section.available?,
            progress:,
            lang: @course.lang,
          }).tap do |segment|
            # Sections without access cannot be expanded.
            next unless accessible?

            # 3. Add all items of the section.
            items.each do |item|
              segment.with_segment_unit(**item.build)
            end
          end
        end

        private

        def accessible?
          @context.course_accessible? || @section.available?
        end

        def items
          @items ||= @context.items_for(@section).map do |item|
            ItemToc.new(context: @context, course: @course, item:)
          end
        end

        # The number of completed items, shown on expandable sections only.
        def progress
          return unless accessible? && @context.user_progress? && items.any?

          {completed: items.count(&:completed?), total: items.size}
        end
      end

      class ItemToc
        include Rails.application.routes.url_helpers

        def initialize(context:, course:, item:)
          @context = context
          @course = course
          @item = item
        end

        def build
          {
            text: @item.title,
            icon: ::Course::Item::Icon.from_resource(@item).icon_class,
            link: ({href: course_item_path(@course.course_code, UUID(@item.id).to_param)} if accessible?),
            locked: !accessible? || !available?,
            deemphasized: @item.deemphasized_in_nav,
            active: @context.active_item?(@item),
            completed: completed?,
            lang: @course.lang,
          }
        end

        def completed?
          return false unless @item.user_state?

          ::Course::Item::ProgressState.new(
            content_type: @item.content_type,
            exercise_type: @item.exercise_type,
            user_state: @item.user_state,
            user_points: @item.result,
            max_points: @item.max_dpoints,
            pass_percentage: @item.pass_percentage
          ).marked?
        end

        private

        # Items outside their dates have no page for the learner. Quizzes past their
        # deadline and locked exams stay linked, as their page explains the lock.
        def accessible?
          previewable? || (@context.content_available? && @item.unlocked?)
        end

        # Items are available within their dates, quizzes also until their
        # submission deadline, and exams once the learner reached the required
        # course progress.
        def available?
          @item.unlocked? && !@item.quiz_deadline_passed?(@context.enrollment) && !exam_locked?
        end

        # Users with access to all content and learners who already submitted
        # the exam (to see their results) are never locked out of it.
        # Users without progress cannot access any content anyway.
        def exam_locked?
          return false if @context.course_accessible? || !@context.user_progress?
          return false if %w[graded submitted].include?(@item.user_state)

          @item.exam_locked_for?(@context.user_id)
        end

        def previewable?
          (@item.open_mode && @item.content_type == 'video') || @context.course_accessible?
        end
      end
    end
  end
end
