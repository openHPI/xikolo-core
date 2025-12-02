# frozen_string_literal: true

module Global
  class SnowflakesEffectPreview < ViewComponent::Preview
    def default
      fake_request = Struct.new(:path).new('/courses/xmas2025')
      component = Global::SnowflakesEffect.new(show_on_paths: ['/courses/xmas2025'])
      component.define_singleton_method(:request) { fake_request }
      render component
    end
  end
end
