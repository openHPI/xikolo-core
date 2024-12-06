# frozen_string_literal: true

module Navigation
  class Section < ApplicationComponent
    renders_many :segments, types: {
      unit: lambda {|**system_arguments|
        Navigation::Item.new(**system_arguments)
      },
      section: lambda {|**system_arguments|
        Navigation::Section.new(**system_arguments)
      },
    }

    def initialize(params)
      @params = params
    end
  end
end
