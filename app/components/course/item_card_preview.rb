# frozen_string_literal: true

module Course
  class ItemCardPreview < ViewComponent::Preview
    TITLE = 'Week 1: How does bias get into AI systems?'

    # @!group Card
    def completed
      render ::Course::ItemCard.new(title: TITLE, label: 'Self-test', icon: 'learning_material', path: '#',
        state: :completed)
    end

    def open
      render ::Course::ItemCard.new(title: TITLE, label: 'Survey', icon: 'survey', path: '#')
    end

    def locked
      render ::Course::ItemCard.new(title: 'Final exam', label: 'Exam', icon: 'exam', state: :locked)
    end

    # Locked, but its page explains why, e.g. an exam requiring more course progress.
    def locked_with_link
      render ::Course::ItemCard.new(title: 'Final exam', label: 'Exam', icon: 'exam', path: '#', state: :locked)
    end

    # The learner's last visited item
    def current
      render ::Course::ItemCard.new(title: TITLE, label: 'Self-test', icon: 'learning_material', path: '#',
        state: :current)
    end

    # An exam graded below its pass percentage
    def failed
      render ::Course::ItemCard.new(title: 'Midterm exam', label: 'Exam', icon: 'exam', path: '#', state: :failed)
    end
    # @!endgroup

    # @!group Row
    def completed_row
      render ::Course::ItemCard.new(title: "1.1. #{TITLE}", label: 'Text', icon: 'text', path: '#',
        state: :completed, layout: :row)
    end

    def open_row
      render ::Course::ItemCard.new(title: "1.2. #{TITLE}", label: 'Video', icon: 'video', path: '#', layout: :row)
    end

    # The learner's last visited item
    def current_row
      render ::Course::ItemCard.new(title: "1.3. #{TITLE}", label: 'Video', icon: 'video', path: '#',
        state: :current, action_label: 'Continue', layout: :row)
    end

    # An exam graded below its pass percentage, with attempts left
    def failed_row
      render ::Course::ItemCard.new(title: '2.4. Midterm exam', label: 'Exam', icon: 'exam', path: '#',
        state: :failed, action_label: 'Retake', layout: :row)
    end

    # An exam graded below its pass percentage, without attempts left
    def failed_without_retake_row
      render ::Course::ItemCard.new(title: '2.4. Midterm exam', label: 'Exam', icon: 'exam', path: '#',
        state: :failed, layout: :row)
    end
    # @!endgroup
  end
end
