# frozen_string_literal: true

module Global
  class AccordionSection < ApplicationComponent
    def initialize(label, id, expanded: false)
      @label = label
      @id = id
      @expanded = expanded
    end

    private

    def expanded
      @expanded ? 'true' : 'false'
    end
  end
end
