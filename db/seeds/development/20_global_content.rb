# frozen_string_literal: true

# Platform-wide content

Page.create!(
  name: 'about',
  locale: 'en',
  title: 'About Xikolo',
  text: <<~MD.strip
    # About Xikolo

    Xikolo is the software behind openHPI and other platforms.
    It is being developed in Potsdam, Germany.
  MD
)
