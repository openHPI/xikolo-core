# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: Show', type: :request do
  subject(:show_channel) { get "/channels/#{channel.code}" }

  let(:channel) do
    create(
      :channel,
      code: 'the-channel',
      stage_visual_uri: 's3://xikolo-public/channels/1/stage_visual_v1.jpg',
      stage_statement: 'Channel Stage'
    )
  end

  let(:page) { Capybara.string(response.body) }

  it 'shows the channel page' do
    show_channel
    expect(response).to be_successful
  end

  context 'with stage items' do
    before do
      channel.courses << create(:course, :active, show_on_stage: true, stage_statement: 'Stage 1')
      channel.courses << create(:course, :active, show_on_stage: true, stage_statement: 'Stage 2')
      channel.courses << create(:course, :active, show_on_stage: false, stage_statement: 'Stage 3')
    end

    it 'shows three stage items' do
      show_channel

      expect(page).to have_content 'Channel Stage'
      expect(page).to have_css('img[src*="https://s3.xikolo.de/xikolo-public/channels/1/stage_visual_v1.jpg"]')

      expect(page).to have_content 'Stage 1'
      expect(page).to have_content 'Stage 2'

      expect(page).to have_no_content 'Stage 3'
    end
  end

  context 'with courses hidden from the public course list' do
    before do
      channel.courses << create(:course, :preparing, title: 'An upcoming course in preparation')
      channel.courses << create(:course, :active, title: 'An active and current course')
      channel.courses << create(:course, :active, title: 'An active and current but not listed course', show_on_list: false)
      channel.courses << create(:course, :active, :hidden, title: 'A hidden course')
      channel.courses << create(:course, :active, :deleted, title: 'A deleted course')
      channel.courses << create(:course, :active, title: 'A group-restricted course', groups: %w[group.1])
      channel.courses << create(:course, :archived, title: 'An archived course')
      channel.courses << create(:course, :archived, title: 'An archived but not listed courses', show_on_list: false)
      channel.courses << create(:course, :upcoming, title: 'A published future course')
    end

    it 'includes courses that should be hidden on the course list' do
      show_channel

      expect(page).to have_content 'An active and current course'
      expect(page).to have_content 'An active and current but not listed course'
      expect(page).to have_content 'An archived course'
      expect(page).to have_content 'An archived but not listed courses'
      expect(page).to have_content 'A published future course'

      expect(page).to have_no_content 'An upcoming course in preparation'
      expect(page).to have_no_content 'A hidden course'
      expect(page).to have_no_content 'A deleted course'
      expect(page).to have_no_content 'A group-restricted course'
    end
  end

  context 'with an info link configured' do
    let(:channel) do
      create(
        :channel,
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
      subject(:show_channel) { get "/channels/#{channel.code}", headers: }

      let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

      before { stub_user_request preferred_language: 'de' }

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
