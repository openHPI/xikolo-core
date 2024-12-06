# frozen_string_literal: true

module CapybaraMatchers
  # rubocop:disable Naming/PredicateName
  def has_notice?(message)
    find '[role=status][aria-live=polite]', text: message
  end
  # rubocop:enable Naming/PredicateName

  Capybara::Session.include CapybaraMatchers
end
