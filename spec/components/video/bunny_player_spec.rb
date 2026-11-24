# frozen_string_literal: true

require 'spec_helper'

describe Video::BunnyPlayer, type: :component do
  subject(:rendered) { Capybara.string(render_inline(component)) }

  let(:component) { described_class.build(video:, course:) }
  let(:course) { create(:course) }
  let(:video) { create(:video, pip_stream: stream) }
  let(:stream) do
    create(:stream, :bunny, title: 'Bunny', provider_video_id: 'bunny-guid', width: 1600, height: 900)
  end

  let(:item) { create(:item, section: create(:section, course:), content: video) }

  before { item }

  describe 'compatible?' do
    it 'is true for a single bunny stream' do
      expect(described_class.compatible?(video)).to be(true)
    end

    context 'with an incomplete upload that has a provider ID' do
      before { stream.update!(upload_state: :uploading) }

      it 'does not expose the player before the upload completes' do
        expect(described_class.compatible?(video)).to be false
      end
    end

    context 'with a failed upload' do
      before { stream.update!(upload_state: :failed) }

      it 'does not offer the incomplete video' do
        expect(described_class.compatible?(video)).to be false
      end
    end

    it 'is false for a vimeo stream' do
      video.update!(pip_stream: create(:stream, :vimeo))
      expect(described_class.compatible?(video)).to be(false)
    end

    it 'is false for multiple display streams' do
      video.update!(pip_stream: stream, lecturer_stream: create(:stream, :bunny))
      expect(described_class.compatible?(video)).to be(false)
    end

    it 'is false for a bunny stream without a provider video id' do
      pending_stream = create(:stream, :bunny, provider_video_id: nil)
      video.update!(pip_stream: pending_stream)
      expect(described_class.compatible?(video)).to be(false)
    end
  end

  context 'with a course teaser' do
    let(:item) { nil }
    let(:poster) { 'https://example.com/course.jpg' }
    let(:component) do
      described_class.build(video:, course:, signed_url_path: '/learn/example/teaser_signed_url', poster:)
    end

    it 'uses the teaser endpoint without requiring a course item' do
      expect(rendered).to have_css('hlsjs-video[src="/learn/example/teaser_signed_url"][playsinline][preload="none"]')
    end

    it 'uses the supplied poster' do
      expect(rendered).to have_css('hlsjs-video[poster="https://example.com/course.jpg"]')
    end

    context 'with subtitles' do
      let!(:subtitle) { create(:video_subtitle, video:) }

      it 'offers the existing subtitles' do
        expect(rendered).to have_css("track[kind='subtitles'][srclang='en'][src='/subtitles/#{subtitle.id}']", visible: :all)
      end
    end
  end

  describe 'rendered player' do
    it 'renders the video.js player, skin and hls media elements' do
      expect(rendered).to have_css('video-player')
      expect(rendered).to have_css('video-player video-skin')
      expect(rendered).to have_css('hlsjs-video')
    end

    it 'points the hls media element at the signed url endpoint' do
      path = Rails.application.routes.url_helpers.signed_url_course_item_path(
        course_id: course.course_code, id: UUID(video.item.id).to_param
      )
      expect(rendered.find('hlsjs-video')[:src]).to eq path
    end

    it 'uses the stream dimensions for the aspect ratio' do
      expect(rendered.find('[data-testid="bunny-player"]')[:style]).to include "--player-side-by-side-ratio: #{16.0 / 9};"
    end

    context 'without an explicit poster' do
      it 'falls back to the signed bunny thumbnail and skips preloading' do
        video = rendered.find('hlsjs-video')
        expect(video[:poster]).to include('bunny-guid/thumbnail.jpg?token=')
        expect(video[:preload]).to eq 'none'
      end
    end

    context 'with subtitles' do
      let(:session) { create(:'account_service/session') }
      let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
      let(:component) { described_class.build(video:, course:, user:) }
      let!(:subtitle_en) { create(:video_subtitle, video:, lang: 'en') }
      let!(:subtitle_de) { create(:video_subtitle, video:, lang: 'de') }
      let(:preferences) do
        {
          'ui.video.video_player_caption_language' => 'de',
          'ui.video.video_player_show_captions' => 'true',
        }
      end

      before { session.user.update!(preferences:) }

      it 'marks the preferred language track as default' do
        expect(rendered).to have_css "track[srclang=de][src='/subtitles/#{subtitle_de.id}'][default]", visible: :all
        expect(rendered).to have_no_css "track[srclang=en][src='/subtitles/#{subtitle_en.id}'][default]", visible: :all
      end

      context 'when the user has no preferred caption language' do
        let(:preferences) { {} }

        it 'does not mark any track as default' do
          expect(rendered).to have_no_css('track[default]', visible: :all)
        end
      end

      context 'when the preference does not match any subtitle' do
        let(:preferences) do
          {'ui.video.video_player_caption_language' => 'fr',
           'ui.video.video_player_show_captions' => 'true'}
        end

        it 'does not mark any track as default' do
          expect(rendered).to have_no_css('track[default]', visible: :all)
        end
      end

      context 'when the user has a preferred language but captions turned off' do
        let(:preferences) do
          {'ui.video.video_player_caption_language' => 'de',
           'ui.video.video_player_show_captions' => 'false'}
        end

        it 'does not mark any track as default' do
          expect(rendered).to have_css "track[srclang=de][src='/subtitles/#{subtitle_de.id}']", visible: :all
          expect(rendered).to have_no_css('track[default]', visible: :all)
        end
      end
    end

    context 'with subtitles and no user' do
      let!(:subtitle_en) { create(:video_subtitle, video:, lang: 'en') }

      it 'does not mark any track as default' do
        expect(rendered).to have_css "track[srclang=en][src='/subtitles/#{subtitle_en.id}']", visible: :all
        expect(rendered).to have_no_css 'track[default]', visible: :all
      end
    end
  end
end
