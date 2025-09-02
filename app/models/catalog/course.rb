# frozen_string_literal: true

module Catalog
  ##
  # A read-only model for loading public lists of courses.
  #
  # This automatically applies filters to hide courses that should not be
  # visible to guests or "normal" learners. (In those contexts, admins should
  # also see things like learners.)
  #
  # In addition, this model exposes additional attributes that are useful for
  # showing course information - by loading this all at once, we avoid N+1
  # query problems.
  #
  class Course < ::ApplicationRecord
    # `embed_courses` is a view, not a table. It includes two additional
    # attributes, which aggregate data from associated tables, namely teachers
    # and classifiers.
    # This is done for easier and efficient reading of this associated data
    # in course list contexts.
    self.table_name = 'embed_courses'
    self.primary_key = :id
    self.ignored_columns += %w[search_data]

    belongs_to :channel, class_name: 'Course::Channel'
    has_many :enrollments,
      class_name: 'Course::Enrollment',
      dependent: :restrict_with_exception
    has_one :visual,
      class_name: 'Course::Visual',
      dependent: :destroy

    # Only ever give access to courses that have not been deleted.
    default_scope { where(deleted: false) }

    PUBLISHED_STATES = %w[active archive].freeze

    class << self
      def started_by(time)
        where(
          '(start_date <= ? AND display_start_date IS NULL) OR display_start_date <= ? OR start_date IS NULL',
          time, time
        )
      end

      def starting_after(time)
        where(
          '(start_date > ? AND display_start_date IS NULL) OR display_start_date > ?',
          time, time
        )
      end

      def ended_by(time)
        where(end_date: ..time)
      end

      def ending_after(time)
        where('end_date > ?', time)
      end

      def order_chronologically
        reorder(Arel.sql('COALESCE(display_start_date, start_date) ASC NULLS LAST, title ASC'))
      end

      def order_recently_finished
        reorder(Arel.sql('COALESCE(end_date, display_start_date, start_date) DESC NULLS LAST, title ASC'))
      end

      ##
      # Order courses by relevance for the user, i.e. show the current or
      # soon starting courses first as they need to be worked on first.
      #
      def order_most_relevant
        reorder(
          Arel.sql('COALESCE(display_start_date, start_date) DESC NULLS LAST, end_date ASC NULLS LAST, title ASC')
        )
      end

      ##
      # Only list courses marked for publication by teachers
      # (i.e., moved out of "preparation" state).
      #
      def released
        where(status: PUBLISHED_STATES)
      end

      def current
        now = ::Time.zone.now

        where(status: 'active').started_by(now).ending_after(now).order_chronologically
      end

      def upcoming
        where(status: 'active').starting_after(::Time.zone.now).order_chronologically
      end

      def self_paced
        now = ::Time.zone.now

        [
          where(status: 'archive'), # Explicitly marked as self-paced
          where(start_date: nil, end_date: nil), # No timebox at all
          started_by(now).where(end_date: nil), # Self-paced since specific date
          ended_by(now), # Timebox has passed
        ].reduce(:or).order_recently_finished
      end

      ##
      # Courses that may appear on "global" course listings,
      # i.e. the course list and some homepage course categories.
      #
      def for_global_list
        where(show_on_list: true)
      end

      ##
      # Courses that may appear on channel course listings.
      #
      def for_channel_list(channel)
        where(channel:)
      end

      ##
      # Courses that a specific user may see in the global course list.
      #
      def for_user(user)
        return for_guests if user.anonymous?

        [
          where(hidden: false).for_groups(user:),
          enrolled_for(user),
        ].reduce(:or)
      end

      ##
      # Courses that anonymous users / search engines may see anywhere.
      #
      def for_guests
        where(hidden: false, groups: [])
      end

      ##
      # Filter by group restrictions.
      #
      # A user may see all courses without group restrictions, and also those
      # restricted to groups they're a member of.
      #
      def for_groups(user:)
        group_names = Account::Group.where_member(user).pluck(:name)

        return where(groups: []) if group_names.blank?

        # Filters to courses that either have no groups or where groups overlap
        # with the given set, e.g. the course and the given group set have at
        # least on group in common.
        #
        # Note: The SQL function `array_length` calculates lengths on a specific
        # dimension (here: 1) and therefore returns NULL on an empty array and
        # not a numeric zero (0).
        #
        # Note: `&&` is PostgreSQLs overlap operator returning TRUE if the right-
        # and left-side arrays have at least on element in common.
        where <<~SQL.squish, group_names
          (array_length(groups, 1) IS NULL OR groups && ARRAY[?]::character varying[])
        SQL
      end

      ##
      # Courses that a specific user is enrolled in.
      #
      def enrolled_for(user)
        return none if user.anonymous?

        enrolled = ::Course::Enrollment.active
          .where(user_id: user.id)
          .select(:course_id)

        where(id: enrolled)
      end

      ##
      # Filter for current courses of a specific user.
      #
      def active_for(user, enrollments)
        # Since the entire relation is reordered, there is no need to apply
        # ordering to sub-queries.
        courses = where(id: enrollments.map(&:course_id))
        [
          courses.current.except(:order, :reordering),
          courses.self_paced.except(:order, :reordering),
        ].reduce(:or).where.not(id: with_achievement(user)).order_most_relevant
      end

      ##
      # Filter for upcoming courses of a specific user.
      #
      def upcoming_for(user, enrollments)
        where(id: enrollments.map(&:course_id))
          .upcoming
          .where.not(id: with_achievement(user))
      end

      ##
      # Filter for completed courses of a specific user.
      #
      def completed_for(user, enrollments)
        [
          where(id: enrollments.map(&:course_id)),
          where(id: with_achievement(user)),
        ].reduce(:or).order_most_relevant
      end

      def with_achievement(user)
        Xikolo.api(:course).value!.rel(:enrollments).get({
          user_id: user.id,
          learning_evaluation: true,
          per_page: 1000,
        }).value!.then do |enrollments|
          enrollments.select { it['completed'] }.pluck('course_id')
        end
      rescue Restify::ResponseError
        []
      end

      ##
      # Match all courses tagged with the given classifier in the given cluster.
      #
      def by_classifier(cluster, classifier)
        # `fixed_classifiers` is a flattened array of `classifiers` table rows,
        # exactly those that are assigned to a course across all clusters.
        #
        # We select all courses having rows in `fixed_classifiers` (`ANY`) that
        # match the pattern preceding the `<@` operator (i.e. the desired
        # subset of key-value pairs in each row).
        where(
          "hstore(ARRAY['cluster_id', 'title'], ARRAY[?, ?]) <@ ANY(fixed_classifiers)",
          cluster, classifier
        )
      end

      ##
      # This search scope is copied from Course#search_by_text in xi-course.
      # Any change there must be reflected here below too.
      #
      def search_by_text(query)
        query.split.reduce(all) do |memo, term|
          term = sanitize_sql_like(term)
          memo.where('search_data ILIKE ?', "%#{term}%")
        end
      end
    end

    ##
    # Is the active course runtime over?
    #
    def over?
      end_date.nil? || end_date.past?
    end

    def started?
      start_date.nil? || start_date.past?
    end

    def published?
      PUBLISHED_STATES.include? status
    end

    ##
    # Has the course content ever been unlocked?
    #
    def was_available?
      published? && started?
    end

    def external?
      external_course_url.present?
    end

    ##
    # Can users enroll to this course by themselves?
    #
    def self_service_enrollment?
      !invite_only? && !external?
    end

    def reactivation_possible?
      on_demand? && over? && was_available?
    end

    def classifiers(cluster_name)
      fixed_classifiers
        .select {|classifier| classifier['cluster_id'] == cluster_name }
        .map do |c|
          Translations.new(JSON.parse(c['translations'])).to_s.presence || c['title'].titleize
        end
    end
  end
end
