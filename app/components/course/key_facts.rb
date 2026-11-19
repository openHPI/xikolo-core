# frozen_string_literal: true

module Course
  class KeyFacts < ApplicationComponent
    Fact = Data.define(:icon, :label, :title)

    # @param course [CourseInfoPresenter]
    def initialize(course)
      @course = course
    end

    def render?
      facts.any?
    end

    private

    def facts
      @facts ||= [level, language, certificate].compact
    end

    def level
      return if @course.level.blank?

      Fact.new(icon: 'cellular-signal-1', label: @course.level, title: nil)
    end

    def language
      return if @course.lang.blank?

      Fact.new(icon: 'globe', label: @course.lang.upcase, title: t(:"languages.name.#{@course.lang}"))
    end

    def certificate
      return unless @course.show_certificate_requirements?

      Fact.new(icon: 'article', label: t('course.key_facts.certificate'), title: nil)
    end
  end
end
