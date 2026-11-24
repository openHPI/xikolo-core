# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: Show', type: :request do
  subject(:show_channel) { get "/channels/#{channel.code}" }

  let(:channel) { create(:'course_service/channel', code: 'the-channel', **attributes) }
  let(:attributes) { {} }
  let(:page) { Capybara.string(response.body) }

  it 'shows the title and breadcrumbs even without images, description, or courses' do
    show_channel

    expect(response).to be_successful
    expect(page).to have_css('h1', exact_text: 'Channel EN', count: 1)
    expect(page).to have_css('header nav.x-breadcrumbs')
    expect(page).to have_css("header[class*='--page-header-bg:var(--color-secondary)']")
    expect(page).to have_link('Channel EN', href: channel_path(channel.code))
  end

  context 'with a subtitle, description and both visuals' do
    let(:attributes) do
      {
        subtitle: {en: 'Discover computer science'},
        description: {en: 'An **introduction** to the channel.'},
        stage_visual_uri: 's3://xikolo-public/channels/stage.jpg',
        mobile_visual_uri: 's3://xikolo-public/channels/mobile.jpg',
      }
    end

    it 'renders the subtitle and responsive visual in the header' do
      show_channel

      expect(page).to have_css('h1', exact_text: 'Channel EN', count: 1)
      expect(page).to have_css('header p', exact_text: 'Discover computer science')
      expect(page).to have_css('header picture img[src*="stage.jpg"]')
      expect(page).to have_css('header picture source[srcset*="mobile.jpg"]', visible: :all)
    end

    it 'shows the description below the course cards and before other channels' do
      channel.courses << create(:course, :active, title: 'An ongoing course')
      create(:'course_service/channel')

      show_channel

      description = page.find_by_id('channel-description')
      expect(description).to have_xpath('preceding-sibling::h2', text: 'More information about this channel')
      expect(description).to have_xpath('preceding::a', text: 'An ongoing course')
      expect(description).to have_xpath('following::h2[@id="other-channels"]')
    end
  end

  context 'with a description but no subtitle' do
    let(:attributes) { {description: {en: 'Learn more about this channel.'}} }

    it 'shows the description below the empty course list without using it as the subtitle' do
      show_channel

      expect(page).to have_css('#channel-description', text: 'Learn more about this channel.')
      expect(page).to have_no_css('header', text: 'Learn more about this channel.')
    end

    it 'keeps the description outside the loading container when filters have no matches' do
      get channel_path(channel.code), params: {q: 'nonexistent'}

      expect(page).to have_css('#channel-description', text: 'Learn more about this channel.')
      expect(page).to have_no_css('[data-hide-on-submit] #channel-description')
    end
  end

  context 'with only a mobile visual' do
    let(:attributes) { {mobile_visual_uri: 's3://xikolo-public/channels/mobile.jpg'} }

    it 'uses it as the fallback image' do
      show_channel

      expect(page).to have_css('header picture img[src*="mobile.jpg"]')
    end
  end

  context 'with Shorts for a channel course' do
    let(:attributes) do
      {
        stage_visual_uri: 's3://xikolo-public/channels/stage.jpg',
        mobile_visual_uri: 's3://xikolo-public/channels/mobile.jpg',
      }
    end
    let(:course) { create(:course, :active) }
    let(:short_status) { 'active' }
    let!(:short) { create(:'course_service/short', course:, status: short_status, bunny_video_id: 'video-guid') }

    before do
      course.channels << channel
      allow(BunnySignedURL).to receive(:new).and_return(instance_double(BunnySignedURL,
        call: {thumbnail: 'https://video.example.com/thumbnail.jpg'}))
    end

    it 'replaces the header visual with a deck of shorts' do
      show_channel

      expect(response).to be_successful
      expect(page).to have_css('header [data-controller~="shorts-deck"]', count: 1)
      expect(page).to have_css("header [data-video-src='#{signed_url_short_path(short.id)}']")
      expect(page).to have_no_css('header picture')
      expect(page).to have_css('h1', exact_text: 'Channel EN', count: 1)
    end

    context 'without an uploaded visual' do
      let(:attributes) { {} }

      it 'still renders the deck in the header' do
        show_channel

        expect(page).to have_css('header [data-controller~="shorts-deck"]')
      end
    end

    context 'when the Short is inactive' do
      let(:short_status) { 'preparation' }

      it 'keeps the responsive visual instead of rendering a deck' do
        show_channel

        expect(page).to have_no_css('[data-controller~="shorts-deck"]')
        expect(page).to have_css('header picture img[src*="stage.jpg"]')
        expect(page).to have_css('header picture source[srcset*="mobile.jpg"]', visible: :all)
      end
    end
  end

  context 'with courses hidden from the public course list' do
    before do
      channel.courses << create(:course, :preparing, title: 'An upcoming course in preparation')
      channel.courses << create(:course, :active, title: 'An active and current course')
      channel.courses << create(:course, :active, title: 'An active and current but not listed course', placement: [])
      channel.courses << create(:course, :active, :hidden, title: 'A hidden course')
      channel.courses << create(:course, :active, :deleted, title: 'A deleted course')
      channel.courses << create(:course, :active, title: 'A group-restricted course', groups: %w[group.1])
      channel.courses << create(:course, :self_paced, title: 'An self_paced course')
      channel.courses << create(:course, :self_paced, title: 'An self_paced but not listed courses', placement: [])
      channel.courses << create(:course, :upcoming, title: 'A published future course')
    end

    it 'excludes courses that should be hidden on the course list' do
      show_channel

      expect(page).to have_text 'An active and current course'
      expect(page).to have_text 'An self_paced course'
      expect(page).to have_text 'A published future course'

      expect(page).to have_no_text 'An active and current but not listed course'
      expect(page).to have_no_text 'An self_paced but not listed courses'
      expect(page).to have_no_text 'An upcoming course in preparation'
      expect(page).to have_no_text 'A hidden course'
      expect(page).to have_no_text 'A deleted course'
      expect(page).to have_no_text 'A group-restricted course'
    end
  end

  context 'when filtering by format' do
    subject(:show_channel) { get "/channels/#{channel.code}?course_format=workshop" }

    before do
      channel.courses << create(:course, :active, title: 'A course', course_format: 'course')
      channel.courses << create(:course, :active, title: 'A workshop', course_format: 'workshop')
    end

    it 'lists only matching learning units' do
      show_channel

      expect(page).to have_text 'A workshop'
      expect(page).to have_no_text 'A course'
    end

    it 'only lists formats that have at least one learning unit' do
      show_channel

      # 'course' and 'workshop' learning units exist, but none for 'project'.
      expect(page).to have_select 'Format', options: %w[All Course Workshop]
    end
  end

  context 'with an info link configured' do
    let(:channel) do
      create(
        :'course_service/channel',
        code: 'the-channel',
        stage_statement: 'Channel Stage',
        info_link: {
          'href' => {'en' => 'https://www.example.com/info', 'de' => 'https://www.example.com/de/info'},
          'label' => {'en' => 'Additional information', 'de' => 'Zusätzliche Informationen'},
        }
      )
    end

    it 'shows the info link' do
      show_channel

      expect(page).to have_link('Additional information', href: 'https://www.example.com/info')
    end

    context 'for logged-in user' do
      subject(:show_channel) { get "/channels/#{channel.code}" }

      before { sign_in(user: create(:'account_service/user', language: 'de')) }

      it "shows the info link in the user's language" do
        show_channel

        expect(page).to have_link('Zusätzliche Informationen', href: 'https://www.example.com/de/info')
      end
    end
  end

  context 'w/o an info link being configured' do
    it 'does not show an info link' do
      show_channel

      expect(page).to have_no_link('Additional information')
    end
  end

  context 'with an unknown channel ID' do
    subject(:show_channel) { get '/channels/unknown' }

    it 'responds with 404 Not Found' do
      expect { show_channel }.to raise_error Status::NotFound
    end
  end

  context 'with a non-canonical URL' do
    subject(:show_channel) { get "/channels/#{channel.id}" }

    it 'redirects to the canonical channel URL' do
      show_channel
      expect(response).to redirect_to("/channels/#{channel.code}")
    end
  end
end
