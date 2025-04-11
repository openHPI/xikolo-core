# frozen_string_literal: true

module Course
  class Achievement < ApplicationComponent
    def initialize(achievement, documents)
      @achievement = achievement
      @documents = documents
    end

    def css_classes
      return 'achievement--achieved' if @achievement['achieved']

      'achievement--in-progress' if @achievement['achievable']
    end

    def show_pill?
      @achievement['achieved'] || @achievement['achievable']
    end

    def pill
      return unless show_pill?

      if @achievement['achieved']
        {color: :success, text: I18n.t('course.certificates.achieved_state')}
      else
        {color: :information, text: I18n.t('course.certificates.in_progress_state')}
      end
    end

    def show_requirements?
      @achievement['requirements'].present?
    end

    def requirements
      return [] unless show_requirements?

      @achievement['requirements'] << open_badge_requirements if open_badge?

      @achievement['requirements'].map {|req| create_requirement(req) }
    end

    def actions
      return [] unless @achievement['download'] || open_badge?

      actions = [@achievement['download']]
      actions << {'label' => 'Show open Badge', 'url' => open_badge_url, 'type' => 'badge'} if open_badge?

      actions.map {|data| action_links(data) }
    end

    def callout_text
      @achievement.dig('download', 'description')
    end

    def title
      @achievement['name']
    end

    def description
      @achievement['description']
    end

    private

    def action_links(data)
      if data['type'] == 'download' && data['available']
        link_to data['url'], class: 'btn btn-primary btn-sm', download: true do
          I18n.t(:'global.download')
        end
      elsif data['type'] == 'progress'
        link_to data['url'], class: 'btn btn-default btn-sm' do
          I18n.t(:'course.certificates.in_progress_button')
        end
      elsif data['type'] == 'badge'
        link_to data['url'], class: 'btn btn-default btn-sm' do
          I18n.t(:'course.certificates.show_open_badge')
        end
      end
    end

    def create_requirement(req)
      css_classes = req['achieved'] ? 'requirement--achieved' : 'requirement--missing'

      content_tag(:li, class: css_classes) do
        concat render(Global::FaIcon.new(req['achieved'] ? 'circle-check' : 'circle-xmark'))
        concat content_tag(:span, req['description'])
      end
    end

    def open_badge?
      record_of_achievement? && @documents.open_badge_enabled?
    end

    def record_of_achievement?
      @achievement['type'] == 'record_of_achievement'
    end

    def open_badge_requirements
      {
        'description' => I18n.t(:'course.courses.show.open_badge_requirements').html_safe,
        'achieved' => @documents.open_badge?,
      }
    end

    def open_badge_url
      course_certificate_path(course_id: @documents.course.course_code, id: "open_badge_#{@documents.course.id}")
    end
  end
end
