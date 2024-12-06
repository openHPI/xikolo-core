# frozen_string_literal: true

module Helpdesk
  class CategoryOptions
    class << self
      def general_question(key, text, opts = {})
        general_questions << Helpdesk::GeneralQuestion.new({key:, text:}.merge(opts))
      end

      def general_questions
        @general_questions ||= []
      end

      def general?(topic)
        general_questions.map(&:key).include? topic
      end

      def default
        general_questions.first.key
      end

      def options_for(user)
        {
          I18n.t(:'helpdesk.general_question') => general_questions
            .select {|option| option.applicable? user }
            .map(&:as_option),
          I18n.t(:'helpdesk.course_specific_question') => all_courses
            .map {|c| [c['title'], c['id']] },
        }
      end

      def all_courses
        Xikolo.api(:course).value!.rel(:courses).get(
          public: true, hidden: false, per_page: 500
        ).value!
      end
    end

    # Add possible options for general questions below
    general_question 'technical', 'helpdesk.technical_question'
    general_question 'reactivation', 'helpdesk.course_reactivation',
      if: ->(user) { user.feature?('course_reactivation') && CourseReactivation.enabled? }

    Xikolo.config.helpdesk&.dig('options')&.each do |key, text|
      general_question(key, text)
    end
  end
end
