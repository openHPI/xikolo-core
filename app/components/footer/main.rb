# frozen_string_literal: true

module Footer
  class Main < ApplicationComponent
    private

    def render?
      Xikolo.config.footer['visible']
    end
  end
end
