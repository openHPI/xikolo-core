# frozen_string_literal: true

module Items
  class Header < ApplicationComponent
    # For admin actions e.g. the 'Edit item' and 'Statistics' links.
    renders_many :actions

    # @param title [String] the item title, e.g. 'Willkommen zum Kurs Digitale Gerechtigkeit'
    # @param icon_class [String] icon class for the item type, e.g. +ItemPresenter#icon_class+
    # @param section_title [String, nil] the title of the section the item belongs to, e.g. 'Module 1'
    # @param lang [String, nil] the language the title is written in, when it differs from the UI locale
    def initialize(title:, icon_class:, section_title: nil, lang: nil)
      @title = title
      @icon_class = icon_class
      @section_title = section_title
      @lang = lang
    end

    def section_title?
      @section_title.present?
    end
  end
end
