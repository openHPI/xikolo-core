# frozen_string_literal: true

module Steps
  module Channels
    Given 'a public channel was created' do
      context.assign :channel, create_channel(public: true)
    end

    Given 'a private channel was created' do
      context.assign :channel, create_channel(public: false)
    end

    Given 'the course belongs to the channel' do
      context.with :course, :channel do |course, channel|
        assign_course_to_channel course, channel
      end
    end

    When(/^I click on the "(.*)" dropdown$/) do |text|
      page.click_on text
    end

    When 'I click on the channel name' do
      context.with :channel do |channel|
        page.click_on channel['name']
      end
    end

    Then(/^I should see a dropdown labeled "(.*)"$/) do |text|
      expect(page).to have_css('[data-behaviour="dropdown"]', text:)
    end

    Then(/^I should not see a dropdown labeled "(.*)" in the platform navigation$/) do |text|
      expect(page).to have_css 'nav.navigation-bar'
      expect(page).not_to have_css('.navigation-item__text', text:)
    end

    Then(/^I should not see a dropdown labeled "(.*)" in the course filter bar$/) do |text|
      expect(page).not_to have_select text
    end

    Then 'I should see the channel name in the dropdown' do
      context.with :channel do |channel|
        expect(page).to have_link channel['name']
      end
    end

    Then "I should be on the channel's page" do
      context.with :channel do |channel|
        expect(page).to have_current_path "/channels/#{channel['code']}"
      end
    end

    def create_channel(public:)
      Server[:course].api.rel(:channels).post({
        code: 'enterprise',
        name: 'Enterprise Channel',
        color: '#FF0000',
        public:,
      }).value!
    end

    def assign_course_to_channel(course, channel)
      Server[:course].api.rel(:course).patch(
        {channel_id: channel['id']},
        params: {id: course['id']}
      ).value!
    end
  end
end

Gurke.configure do |c|
  c.include Steps::Channels
end
