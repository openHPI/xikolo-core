# frozen_string_literal: true

require 'spec_helper'

describe Video::VideoPlayer, type: :component do
  subject(:rendered) { Capybara.string(render_inline(component)) }

  let(:component) { described_class.new(video, user:, opts:) }
  let(:video) { create(:video, pip_stream:) }
  let(:features) { {} }
  let(:opts) { {} }
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session(user_session) }
  let(:user_session) do
    {
      'masqueraded' => false,
      'features' => features,
      'user_id' => '51f544b6-a9c7-4bfe-b76b-43a4441d36c3',
      'user' => {
        'anonymous' => false,
        'language' => I18n.locale,
        'preferred_language' => I18n.locale,
      },
    }
  end
  let(:preferences) { {} }
  let(:pip_stream) do
    create(:stream, :vimeo,
      id: '00000002-3600-4444-9999-000000000001',
      title: 'Pip',
      provider_video_id: '1234567',
      hd_url: 'http://xikolo.de/pip.hd.mp4',
      sd_url: 'http://xikolo.de/pip.sd.mp4',
      width: 1600,
      height: 900,
      duration: 180)
  end
  let(:slides_stream) do
    create(:stream, :vimeo,
      id: '00000002-3600-4444-9999-000000000002',
      title: 'Slides',
      provider_video_id: '7654321',
      hd_url: 'http://xikolo.de/slides.hd.mp4',
      sd_url: 'http://xikolo.de/slides.sd.mp4',
      width: 1600,
      height: 900,
      duration: 180)
  end
  let(:lecturer_stream) do
    create(:stream, :kaltura,
      id: '00000002-3600-4444-9999-000000000003',
      title: 'Lecturer',
      provider_video_id: '1_klqqno3b',
      hd_url: 'http://xikolo.de/lecturer.hd.mp4',
      sd_url: 'http://xikolo.de/lecturer.sd.mp4',
      width: 1600,
      height: 900,
      duration: 180)
  end

  before do
    allow(user).to receive(:preferences).and_return(
      Restify::Promise.fulfilled(preferences)
    )
  end

  context 'when a video has all streams' do
    let(:video) { create(:video, lecturer_stream:, slides_stream:, pip_stream:) }

    it 'renders the player with two video components' do
      expect(rendered).to have_css "xm-kaltura[name=primary][partner-id='1234567'][entry-id='1_klqqno3b'][duration=180][ratio='0.5625']"
      expect(rendered).to have_css "xm-vimeo[name=secondary][src='7654321']"
    end

    it 'renders a presentation component with two references' do
      expect(rendered).to have_css "xm-presentation[reference='primary,secondary']"
    end
  end

  context 'when a video only has a PiP stream' do
    it 'renders the player with only one xm-vimeo tag' do
      expect(rendered).to have_css "xm-vimeo[name=primary][src='1234567']"
      expect(rendered).to have_no_selector '[name=secondary]'
    end

    it 'renders a presentation component with one reference' do
      expect(rendered).to have_css 'xm-presentation[reference=primary]'
    end

    it 'does not add text tracks' do
      expect(rendered).to have_no_selector 'xm-text-track'
    end
  end

  context 'with subtitles' do
    let!(:subtitle_de) { create(:video_subtitle, video:, lang: 'de') }
    let!(:subtitle_en) { create(:video_subtitle, video:, lang: 'en') }
    let!(:subtitle_id) { create(:video_subtitle, video:, lang: 'id') }

    it 'renders a DOM element for each subtitle language' do
      expect(rendered).to have_css "xm-text-track[language=de][src='/subtitles/#{subtitle_de.id}'][label=Deutsch][position=1]"
      expect(rendered).to have_css "xm-text-track[language=en][src='/subtitles/#{subtitle_en.id}'][label=English][position=2]"
      expect(rendered).to have_css "xm-text-track[language=id][src='/subtitles/#{subtitle_id.id}'][label='Bahasa Indonesia'][position=0]"
    end

    it 'sorts the subtitles by language name' do
      tracks = rendered.all 'xm-text-track'
      expect(tracks.pluck('language')).to eq %w[id de en]
      expect(tracks.pluck('position')).to eq %w[0 1 2]
    end
  end

  context 'with subtitles marked as auto-generated' do
    let!(:subtitle_de) { create(:video_subtitle, video:, lang: 'de', automatic: true) }
    let!(:subtitle_en) { create(:video_subtitle, video:, lang: 'en') }

    it 'highlights auto-translated subtitles using their label' do
      expect(rendered).to have_css "xm-text-track[language=en][src='/subtitles/#{subtitle_en.id}'][label=English]"
      expect(rendered).to have_css "xm-text-track[language=de][src='/subtitles/#{subtitle_de.id}'][label='Deutsch (auto-generated)']"
    end
  end

  describe 'interactive transcript' do
    context 'with subtitles' do
      before do
        create(:video_subtitle, video:, lang: 'de')
        create(:video_subtitle, video:, lang: 'en')
        create(:video_subtitle, video:, lang: 'id')
      end

      it 'registers a button with the player for toggling the interactive transcript' do
        player = rendered.find 'xm-player'
        button = player.find 'xm-toggle-control[name=toggle_transcript]'

        expect(button[:title]).to eq 'Transcript'
        expect(button).to have_css 'svg[slot=icon]'
      end

      it 'has an inactive toggle control button' do
        button = rendered.find 'xm-toggle-control[name=toggle_transcript]'
        expect(button).to have_no_selector '[active]'
      end

      it 'does not show the transcript' do
        transcript = rendered.find('[data-transcript]', visible: :all)
        expect(transcript.visible?).to be false
      end
    end

    context 'without subtitles' do
      it 'does not register the button' do
        player = rendered.find 'xm-player'
        expect(player).to have_no_selector 'xm-toggle-control[name=toggle_transcript]'
      end

      it 'does not render the transcript' do
        player = rendered.find 'xm-player'
        expect(player).to have_no_selector '[data-transcript]'
      end
    end

    context 'with user preferences set to show transcript' do
      let(:preferences) do
        {
          'ui.video.video_player_show_transcript' => 'true',
        }
      end

      before { create(:video_subtitle, video:, lang: 'en') }

      it 'has an active toggle control button' do
        player = rendered.find 'xm-player'
        expect(player).to have_css 'xm-toggle-control[name=toggle_transcript][active]'
      end

      it 'shows the transcript by default' do
        transcript = rendered.find('[data-transcript]')
        expect(transcript.visible?).to be true
      end
    end

    context 'with user preferences set to show transcript without subtitles' do
      let(:preferences) do
        {
          'ui.video.video_player_show_transcript' => 'true',
        }
      end

      it 'has no toggle control button' do
        player = rendered.find 'xm-player'
        expect(player).to have_no_selector 'xm-toggle-control[name=toggle_transcript]'
      end

      it 'does not render the transcript' do
        player = rendered.find 'xm-player'
        expect(player).to have_no_selector '[data-transcript]'
      end
    end

    context 'with user preferences set to not show transcript' do
      let(:preferences) do
        {
          'ui.video.video_player_show_transcript' => 'false',
        }
      end

      before { create(:video_subtitle, video:, lang: 'en') }

      it 'has an inactive toggle control button' do
        button = rendered.find 'xm-toggle-control[name=toggle_transcript]'
        expect(button).to have_no_selector '[active]'
      end

      it 'does not show the transcript by default' do
        transcript = rendered.find('[data-transcript]', visible: :all)
        expect(transcript.visible?).to be false
      end
    end
  end

  describe 'user_preferences' do
    let!(:subtitle_de) { create(:video_subtitle, video:, lang: 'de') }
    let!(:subtitle_en) { create(:video_subtitle, video:, lang: 'en') }
    let(:preferences) do
      {
        'ui.video.video_player_speed' => '1.25',
        'ui.video.video_player_caption_language' => 'de',
        'ui.video.video_player_show_captions' => 'true',
      }
    end

    it 'renders the player with the user preferences properties' do
      expect(rendered).to have_css("xm-player[playbackrate='1.25']")
        .and have_css('xm-player[showsubtitle]')
    end

    it 'highlights the default subtitle' do
      expect(rendered).to have_css "xm-text-track[language=en][src='/subtitles/#{subtitle_en.id}'][label=English]"
      expect(rendered).to have_css "xm-text-track[language=de][src='/subtitles/#{subtitle_de.id}'][label='Deutsch'][default]"
    end

    context 'when the user preferences have an invalid value' do
      let(:preferences) do
        {
          'ui.video.video_player_speed' => '0.3',
          'ui.video.video_player_caption_language' => 'en',
          'ui.video.video_player_show_captions' => 'false',
        }
      end

      it 'renders the player without that user preferences value' do
        expect(rendered).to have_no_selector "xm-player[playbackrate='0.3']"
        expect(rendered).to have_no_selector 'xm-player[showsubtitle]'
      end
    end
  end

  describe '#thumbnails' do
    context 'without thumbnails enabled' do
      it 'does not pass the thumbnails info to the player component' do
        expect(rendered).to have_no_selector('xm-player[slides-src]')
      end
    end

    context 'with thumbnails enabled' do
      let(:features) { {'video_slide_thumbnails' => true} }

      context 'without loaded thumbnails' do
        it 'does not pass the thumbnails to the player component' do
          expect(rendered).to have_no_selector('xm-player[slides-src]')
        end
      end

      context 'with loaded thumbnails' do
        let(:opts) { {load_thumbnails: true} }

        context 'with slides extracted' do
          before { create(:thumbnail, video:) }

          it 'passes the thumbnails information' do
            expect(rendered).to have_css("xm-player[slides-src='[{\"thumbnail\":\"https://s3.xikolo.de/xikolo-video/videos/1/1.png\",\"startPosition\":5}]']")
          end
        end

        context 'with no slides extracted' do
          it 'does not pass the thumbnails to the player component' do
            expect(rendered).to have_no_selector('xm-player[slides-src]')
          end
        end
      end
    end
  end
end
