# frozen_string_literal: true

require 'spec_helper'

describe Global::Mascot, type: :component do
  it 'shows the mascot and its message' do
    render_inline(described_class.new(message: "Nothing unlocked yet? You've got this!"))

    expect(page).to have_css 'img[src*="mascot"][alt=""]'
    expect(page).to have_css '.x-chat-bubble', text: "Nothing unlocked yet? You've got this!"
  end

  it 'keeps the mascot without a speech bubble when there is no message' do
    render_inline(described_class.new(message: nil))

    expect(page).to have_css 'img[src*="mascot"][alt=""]'
    expect(page).to have_no_css '.x-chat-bubble'
  end
end
