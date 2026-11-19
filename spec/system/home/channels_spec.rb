# frozen_string_literal: true

require 'spec_helper'

describe 'Course Channels', type: :system do
  let(:course) { create(:course, title: 'Awesome Channel Course') }

  context 'with a public channel' do
    let(:channel) { create(:'course_service/channel', public: true, title_translations: {'en' => 'Enterprise Channel', 'de' => 'Enterprise Channel'}, code: 'enterprise') }

    before do
      course.channels << channel
    end

    it 'allows channel navigation via dropdown' do
      visit root_path

      click_on 'Channels'
      click_on 'Enterprise Channel'

      # Then I should be on the channel's page
      expect(page).to have_current_path("/channels/#{channel.code}")

      # And the course should be listed
      expect(page).to have_text('Awesome Channel Course')
    end
  end

  context 'with a private channel' do
    let(:channel) { create(:'course_service/channel', public: false, title_translations: {'en' => 'Secret Channel', 'de' => 'Secret Channel'}, code: 'secret') }

    before do
      course.channels << channel
    end

    it 'hides the channel from the platform navigation dropdown' do
      visit root_path

      expect(page).to have_css('nav.navigation-bar')
      expect(page).to have_no_css('.navigation-item__text', text: 'Channels')
    end

    it 'hides the channel from the course filter bar' do
      visit courses_path

      expect(page).to have_text('Happening now')
      expect(page).to have_no_select('Channel')
    end
  end
end
