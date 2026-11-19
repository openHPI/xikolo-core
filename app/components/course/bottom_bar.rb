# frozen_string_literal: true

module Course
  class BottomBar < ApplicationComponent
    renders_one :navigation, ->(component:) { component }
    renders_one :primary_action

    attr_reader :navigation_content, :primary_action_content

    def before_render
      content
      @navigation_content = navigation&.to_s
      @primary_action_content = primary_action&.to_s
    end

    def render?
      navigation_content.present? || primary_action_content.present?
    end
  end
end
