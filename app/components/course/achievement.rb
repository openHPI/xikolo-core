# frozen_string_literal: true

module Course
  class Achievement < ApplicationComponent
    def initialize(achievement)
      @achievement = achievement
    end

    private

    def css_classes
      if @achievement['achieved']
        'is-achieved'
      elsif @achievement['achievable']
        'is-in-progress'
      else
        @achievement['is-not-achieved']
      end
    end

    def pill
      return unless @achievement['achieved'] || @achievement['achievable']

      if @achievement['achieved']
        {icon: Global::FaIcon.new('check', style: :solid), text: I18n.t('course.certificates.achieved_state')}
      else
        {icon: Global::FaIcon.new('pencil', style: :solid), text: I18n.t('course.certificates.in_progress_state')}
      end
    end

    def requirements
      @achievement['requirements'].map do |req|
        Requirement.new req
      end
    end

    def action
      return unless @achievement['download']

      Action.new @achievement['download']
    end

    class Requirement
      def initialize(data)
        @data = data
      end

      def description
        @data['description']
      end

      def css_classes
        @data['achieved'] ? 'is-achieved' : 'is-missing'
      end

      def icon
        name = @data['achieved'] ? 'check' : 'xmark'
        Global::FaIcon.new(name, style: :solid)
      end
    end

    class Action
      def initialize(data)
        @data = data
      end

      def button
        case @data['type']
          when 'download'
            Global::DownloadButton.new(
              @data['url'],
              I18n.t(:'global.download'),
              attributes: {disabled: !@data['available']},
              type: :download
            )
          when 'progress'
            Global::DownloadButton.new(
              @data['url'],
              I18n.t(:'course.certificates.in_progress_button'),
              css_classes: 'btn btn-default btn-outline',
              type: :progress
            )
        end
      end

      def text
        @data['description']
      end
    end
  end
end
