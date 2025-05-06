# frozen_string_literal: true

module Navigation
  class TableOfContents < ApplicationComponent
    renders_many :sections, Navigation::Section

    class << self
      def for_course(...)
        CourseToc.new(...).build
      end

      def for_collabspace(...)
        CollabspaceToc.new(...).build
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
          # 1. Add course syllabus if enabled.
          if @course.show_syllabus
            toc.with_section(
              **SyllabusToc.new(context: self, course: @course).build
            )
          end

          # 2. Add all public (visible) sections, including alternative sections.
          published_sections.each do |section|
            SectionToc.new(context: self, course: @course, section:)
              .build { toc.with_section(**it) }

            next unless section.section_choices?

            section.section_choices.each do |alternative|
              SectionToc.new(context: self, course: @course, section: alternative)
                .build { toc.with_section(**it) }
            end
          end
        end
      end

      def active_page?(path)
        @context.current_page?(path)
      end

      def active_section?(section)
        !@current_section.nil? && (@current_section.id == section.id)
      end

      def active_item?(item)
        @current_item.present? && @current_item['id'] == item.id
      end

      def course_accessible?
        @user.allowed?('course.content.access')
      end

      private

      def published_sections
        @sections.filter_map do |section|
          SectionPresenter.new(section:, user: @user) if section.published?
        end
      end

      class SyllabusToc
        include Rails.application.routes.url_helpers

        def initialize(context:, course:)
          @context = context
          @course = course
        end

        def build
          {
            text: I18n.t(:'courses.nav.syllabus'),
            link: {href: course_overview_path(@course.course_code)},
            active: @context.active_page?(course_overview_path(@course.course_code)),
          }
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
          tooltip = if @section&.start_date&.future?
                      "#{I18n.t(:'sections.locked_until',
                        date: I18n.l(@section.start_date.in_time_zone.to_datetime,
                          format: :very_short_datetime))} (#{Time.zone.name})"
                    elsif @section&.end_date&.past?
                      "#{I18n.t(:'sections.locked_since',
                        date: I18n.l(@section.end_date.in_time_zone.to_datetime,
                          format: :very_short_datetime))} (#{Time.zone.name})"
                    else
                      ''
                    end

          yield({
            text: @section.title,
            link: if @context.course_accessible? || @section.available?
                    {href: course_section_path(@course.course_code, @section)}
                  end,
            active: @context.active_section?(@section),
            tooltip:,
            locked: !@section.available?,
            lang: @course.lang,
          }).tap do |segment|
            next unless @context.active_section?(@section)

            # 3. Add all (promoted) items for the active section.
            @section.items.each do |item|
              next unless item.show_in_side_nav?

              segment.with_segment_unit(
                **ItemToc.new(context: @context, course: @course, item:).build
              )
            end

            # 4. Add the forum link for this section if the forum is enabled and
            # it is *not* a parent section for section alternatives.
            if @course.pinboard_enabled && !@section.alternatives?
              segment.with_segment_unit(
                **DiscussionsToc.new(context: @context, course: @course, section: @section).build
              )
            end
          end
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
            link: if @context.course_accessible? || !@item.locked?
                    {href: course_item_path(@course.course_code, @item)}
                  end,
            locked: @item.locked?,
            active: @context.active_item?(@item),
            lang: @course.lang,
          }
        end
      end

      class DiscussionsToc
        include Rails.application.routes.url_helpers

        def initialize(context:, course:, section:)
          @context = context
          @course = course
          @section = section
        end

        def build
          {
            text: I18n.t(:'courses.nav.discussions'),
            link: {href: course_section_pinboard_index_path(@course.course_code, @section)},
            active: @context.active_page?(course_section_pinboard_index_path(@course.course_code, @section)),
          }
        end
      end
    end

    class CollabspaceToc
      include Rails.application.routes.url_helpers

      def initialize(context:, request:)
        @context = context
        @request = request
      end

      def build
        ::Navigation::TableOfContents.new.tap do |toc|
          # 1. Add general collabspace links.
          toc.with_section(
            text: I18n.t(:'learning_rooms.nav.dashboard'),
            link: {href: course_learning_room_path(@context.course_code, @context.collabspace_id)},
            tooltip: 'Dashboard',
            active: @context.current_page?(course_learning_room_path(@context.course_code, @context.collabspace_id))
          )
          toc.with_section(
            text: I18n.t(:'learning_rooms.nav.discussions'),
            link: {href: course_learning_room_pinboard_index_path(@context.course_code, @context.collabspace_id)},
            tooltip: 'Team Forum',
            active: @request.fullpath.include?(course_learning_room_pinboard_index_path(@context.course_code,
              @context.collabspace_id)) ||
              @request.fullpath.include?(course_learning_room_question_index_path(@context.course_code,
                @context.collabspace_id))
          )
          toc.with_section(
            text: I18n.t(:'learning_rooms.nav.etherpad'),
            link: {href: etherpad_url, target: '_blank'},
            tooltip: 'Etherpad',
            active: false
          )
          toc.with_section(
            text: I18n.t(:'learning_rooms.nav.files'),
            link: {href: course_learning_room_files_path(@context.course_code, @context.collabspace_id)},
            tooltip: 'Files',
            active: @context.current_page?(course_learning_room_files_path(@context.course_code,
              @context.collabspace_id))
          )

          # 2. Add calender link if enabled.
          if @context.include_calendar
            toc.with_section(
              text: I18n.t(:'learning_rooms.nav.calendar'),
              link: {href: course_learning_room_calendar_path(@context.course_code, @context.collabspace_id)},
              tooltip: 'Calendar',
              active: @context.current_page?(course_learning_room_calendar_path(@context.course_code,
                @context.collabspace_id))
            )
          end

          # 4. Add collabspace membership management links if the user is a
          # collabspace mentor or admin.
          if %w[admin mentor].include?(@context.membership.try(:[], 'status')) || @context.super_privileged
            toc.with_section(
              text: I18n.t(:'learning_rooms.nav.administration'),
              link: {href: edit_course_learning_room_path(@context.course_code, @context.collabspace_id)},
              tooltip: 'Administration',
              active: @context.current_page?(edit_course_learning_room_path(@context.course_code,
                @context.collabspace_id))
            )
          end
        end
      end
      private

      def etherpad_url
        template = Addressable::Template.new(Xikolo.config.etherpad_host_template)
        template.expand(id: Digest::MD5.hexdigest(@context.collabspace_id)).to_s
      end
    end
  end
end
