# frozen_string_literal: true

require 'spec_helper'

describe Util::RelativeTimeTag, type: :component do
  subject(:component) { described_class.new(time) }

  let(:time) { DateTime.now }

  describe '#render' do
    it 'includes the time without adjustments for progressive enhancement' do
      render_inline(component)
      expect(page).to have_css("[data-controller='relative-time']")
      expect(page).to have_text(time.to_s) # We cannot test JS in component specs, yet.
    end

    context 'with a limit configured' do
      subject(:component) { described_class.new(time, limit: limit) }

      let(:limit) { 10.days.ago }

      it 'includes the limit data attribute' do
        render_inline(component)
        expect(page).to have_css("[data-limit='#{limit.iso8601}']")
      end
    end
  end
end
