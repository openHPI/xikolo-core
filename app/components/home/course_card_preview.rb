# frozen_string_literal: true

module Home
  # @label Course cards
  class CourseCardPreview < ViewComponent::Preview
    # @group Course cards
    def default
      render_card(level: nil, topics: [])
    end

    def project
      render_card(course_format: 'project', title: 'Build your first web application')
    end

    def workshop
      render_card(course_format: 'workshop', title: 'A practical introduction to databases')
    end

    def upcoming
      render_card(display_start_date: 1.week.from_now)
    end

    def completed
      render_card(completed: true, progress: 100)
    end

    def enrolled_without_progress
      render_card(enrolled: true)
    end

    def enrolled_with_progress
      render_card(enrolled: true, progress: 30)
    end

    def fully_visited
      render_card(enrolled: true, progress: 100)
    end

    def manually_completed_with_partial_progress
      render_card(completed: true, progress: 30)
    end

    def upcoming_and_completed
      render_card(completed: true, display_start_date: 1.week.from_now)
    end

    def with_topics_and_level
      render_card(level: 'Beginner', topics: %w[Programming Databases])
    end

    def intermediate
      render_card(level: 'Intermediate')
    end

    def expert
      render_card(level: 'Expert')
    end

    def with_long_title
      render_card(
        title: 'An introduction to relational databases, distributed systems, and modern web application development'
      )
    end

    def with_many_topics
      render_card(topics: [
        'Programming',
        'Databases',
        'Web development',
        'Distributed information systems',
        'Software engineering',
      ])
    end

    def german_language
      render_card(lang: 'de', title: 'Einführung in relationale Datenbanken')
    end
    # @endgroup

    private

    def render_card(completed: false, enrolled: false, progress: 0, level: 'Beginner',
                    topics: %w[Programming Databases], **attributes)
      course = Catalog::Course.new({
        id: SecureRandom.uuid,
        course_code: 'databases',
        title: 'Everything about databases',
        start_date: 2.weeks.ago,
        end_date: 3.weeks.from_now,
        published: true,
        course_format: 'course',
        lang: 'en',
        fixed_classifiers: classifiers(level:, topics:),
      }.merge(attributes))
      enrollment = if enrolled || completed
                     ::CourseService::Enrollment.instantiate('completed' => completed, 'visits_percentage' => progress)
                   end
      card = Home::CourseCard.new(course, enrollment:)

      # Show the fixture metadata without creating clusters or changing the
      # platform's cluster visibility settings.
      card.define_singleton_method(:visible_clusters) { %w[topic level] }

      render card
    end

    def classifiers(level:, topics:)
      classifiers = topics.map { classifier('topic', it) }
      classifiers << classifier('level', level) if level
      classifiers
    end

    def classifier(cluster, title)
      {
        'cluster_id' => cluster,
        'title' => title,
        'translations' => '{}',
      }
    end
  end
end
