# frozen_string_literal: true

class LanguagePreferences
  def initialize(available_languages:, user:, request:)
    @available_languages = available_languages
    @user = user
    @request = request
  end

  # Sorts available languages by user preference and alphabetically.
  #
  # This method prioritizes user-preferred languages, followed by other
  # available languages sorted alphabetically. If no user-preferred languages
  # are found, all available languages are sorted alphabetically.
  #
  # Example:
  # - Preferred languages: ["en", "de"]
  # - Available languages: ["en", "de", "fr"]
  # - Output: ["en", "de", "fr"]
  #
  # @return [Array<String>] A list of available languages sorted with user-preferred languages first.
  def sort
    preferred, others = partition_languages
    preferred + others.sort
  end

  # Prepares a language filter for use in the UI, prioritizing user-preferred
  # languages.
  #
  # This method localizes and categorizes the available languages for display
  # in a filter component.
  # Preferred languages (if any) appear first, followed by a divider and other
  # available languages sorted alphabetically. If no preferred languages are
  # found, all available languages are sorted alphabetically.
  #
  # Example:
  # - Preferred languages: ["en", "de"]
  # - Available languages: ["en", "de", "fr"]
  # - Output:
  #   [
  #     "English (English)",
  #     "German (Deutsch)",
  #     "---",
  #     "French (Français)"
  #   ]
  #
  # Notes:
  # - The divider (`---`) is only included if both preferred and non-preferred
  #   languages are present.
  #
  # @return [Global::FilterBar::Filter] A filter object containing the localized and categorized language list.
  def for_filter(selected_language:)
    preferred, others = partition_languages
    localized_preferred = localize_languages(preferred)
    localized_others = localize_languages(others).sort

    languages = if preferred.empty?
                  localized_others
                elsif others.empty?
                  localized_preferred
                else
                  localized_preferred + [I18n.t(:'components.filter_bar.filter.divider')] + localized_others
                end

    Global::FilterBar::Filter.new(
      :lang,
      I18n.t(:'course.courses.index.filter.language'),
      languages,
      selected: selected_language
    )
  end

  private

  def partition_languages
    preferred_languages = compatible_user_languages
    others = @available_languages - preferred_languages
    [preferred_languages, others]
  end

  # Determines the user's preferred languages based on their profile and browser
  # settings.
  #
  # The method first considers the user's explicitly selected preferred language,
  # and then appends the preferred languages parsed from the HTTP `Accept-Language`
  # header.
  #
  # Example:
  # - User's preferred language: "en"
  # - HTTP `Accept-Language`: ["en-US", "en", "de"]
  # - Available languages: ["en", "de", "fr"]
  #
  # Result: ["en", "en-US", "de"]
  #
  # Notes:
  # - If the user is not logged in or their preferred language is not available,
  #   only the browser-preferred languages are included.
  # - Languages not in the list of available languages are excluded.
  #
  # @return [Array<String>] A list of languages ordered by preference:
  #   1. The user's selected preferred language (if applicable).
  #   2. Languages from the HTTP `Accept-Language` header, in their original order.
  def compatible_user_languages
    http_accept_languages.tap do |languages|
      if @user&.logged_in? && @available_languages.include?(@user.preferred_language)
        languages.unshift @user.preferred_language # Insert preferred language at first position
      end
    end.uniq
  end

  def http_accept_languages
    # The Accept-Language request HTTP header returns the language preferred by
    # the client. The http_accept_languages gem helps to parse the values and
    # returns an array of the user's preferred languages.
    # Example: ["en-US", "en", "es-AR", "es", "de"]
    http_accept_languages = HttpAcceptLanguage::Parser.new(@request.env['HTTP_ACCEPT_LANGUAGE'])

    # Drop languages that are not available, e.g. via course subtitles.
    # If the language is a variant (e.g. "de-CH"), check for support for its
    # parent language (e.g., "de") before dropping it and removing duplicates.
    # Result for the sample from above: ["en", "es", "de"]
    compatible_languages_from(http_accept_languages.user_preferred_languages).uniq
  end

  def compatible_languages_from(preferred_languages)
    preferred_languages.filter_map do |lang| # Example: en-US
      base, _variant = lang.downcase.split('-', 2)
      @available_languages.find do |available|
        available.casecmp?(lang) || available.casecmp?(base)
      end
    end
  end

  def localize_languages(languages)
    languages.map do |lang|
      platform_localization = I18n.t("languages.title.#{lang}")
      native_localization = I18n.t("languages.name.#{lang}")
      ["#{platform_localization} (#{native_localization})", lang]
    end
  end
end
