# frozen_string_literal: true

module Items
  class HeaderPreview < ViewComponent::Preview
    # @!group Item types
    def default
      render ::Items::Header.new(
        title: 'Willkommen zum Kurs Digitale Gerechtigkeit',
        icon_class: icon_for('Video::Video'),
        section_title: 'Module 1'
      )
    end

    def without_section
      render ::Items::Header.new(
        title: 'Willkommen zum Kurs Digitale Gerechtigkeit',
        icon_class: icon_for('CourseService::Richtext')
      )
    end

    def long_title
      render ::Items::Header.new(
        title: 'Wie digitale Gerechtigkeit in einer vernetzten Gesellschaft entsteht und warum sie uns alle ' \
               'betrifft – ein umfassender Überblick über die Chancen und Risiken der digitalen Transformation',
        icon_class: icon_for('QuizService::Quiz', exercise_type: 'selftest'),
        section_title: 'Module 4: Digitale Teilhabe und ihre Grenzen'
      )
    end

    def with_actions
      render ::Items::Header.new(title: 'Was ist digitale Gerechtigkeit?', icon_class: icon_for('Video::Video'),
        section_title: 'Module 1') do |c|
        c.with_action { '<a href="#" class="x-btn x-btn-xs x-btn-outline">Edit item</a>'.html_safe }
        c.with_action { '<a href="#" class="x-btn x-btn-xs x-btn-outline">Statistics</a>'.html_safe }
      end
    end

    def video
      render ::Items::Header.new(title: 'Was ist digitale Gerechtigkeit?', icon_class: icon_for('Video::Video'),
        section_title: 'Module 1')
    end

    def rich_text
      render ::Items::Header.new(title: 'Kursüberblick', icon_class: icon_for('CourseService::Richtext'),
        section_title: 'Module 1')
    end

    def quiz
      render ::Items::Header.new(title: 'Selbsttest zur ersten Woche',
        icon_class: icon_for('QuizService::Quiz', exercise_type: 'selftest'), section_title: 'Module 1')
    end

    def lti_exercise
      render ::Items::Header.new(title: 'Programmieraufgabe', icon_class: icon_for('Lti::Exercise'),
        section_title: 'Module 2')
    end

    def cmi5
      render ::Items::Header.new(title: 'Interaktive Übung', icon_class: icon_for('Cmi5::Item'),
        section_title: 'Module 2')
    end

    # @!endgroup

    private

    def icon_for(content_type, exercise_type: nil)
      item = {'content_type' => content_type, 'exercise_type' => exercise_type}

      ::Course::Item::Icon.from_resource(item).icon_class
    end
  end
end
