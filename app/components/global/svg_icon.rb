# frozen_string_literal: true

module Global
  # This component is used to display an svg file inline.
  # The file path should be provided as a string, or as ruby Pathname object.
  # The wrapping_class will be added to the wrapping <span> tag's class attribute.
  class SvgIcon < ApplicationComponent
    def initialize(path, wrapping_class:)
      @path = path
      @wrapping_class = wrapping_class
    end

    private

    def svg
      File.read(@path)
    end
  end
end
