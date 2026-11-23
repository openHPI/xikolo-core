# frozen_string_literal: true

require 'spec_helper'

describe Home::ChannelPresenter, type: :presenter do
  subject(:channel_presenter) { described_class.new(channel) }

  let(:channel_description) { {en: 'Test description', de: 'Testbeschreibung'} }
  let(:channel) { build(:'course_service/channel', description: channel_description) }

  describe '#subtitle' do
    let(:channel) { build(:'course_service/channel', subtitle:) }
    let(:subtitle) { {'en' => 'Start coding', 'de' => 'Starte mit Programmieren'} }

    it 'uses the current locale' do
      I18n.with_locale(:de) do
        expect(channel_presenter.subtitle).to eq 'Starte mit Programmieren'
      end
    end

    context 'when the requested translation is missing' do
      let(:subtitle) { {'en' => 'Start coding'} }

      it 'falls back to an available translation' do
        I18n.with_locale(:de) do
          expect(channel_presenter.subtitle).to eq 'Start coding'
        end
      end
    end

    context 'without a subtitle' do
      let(:subtitle) { nil }

      it 'is empty' do
        expect(channel_presenter.subtitle).to be_empty
      end
    end
  end

  describe '#shorts' do
    let(:channel) { create(:'course_service/channel') }
    let(:course) { create(:'course_service/course', skip_account_groups: true) }

    before do
      course.channels << channel
    end

    it 'returns the short id and a signed thumbnail URL for active shorts of the channel courses' do
      short = create(:'course_service/short', course_id: course.id, status: 'active', bunny_video_id: 'video-guid')

      signed = {video: 'https://vz-test.b-cdn.net/video-guid/playlist.m3u8?token=tok', thumbnail: 'https://vz-test.b-cdn.net/video-guid/thumbnail.jpg?token=tok'}
      allow(BunnySignedURL).to receive(:new).and_return(instance_double(BunnySignedURL, call: signed))

      expect(channel_presenter.shorts).to eq [
        {
          id: short.id,
          thumbnail: 'https://vz-test.b-cdn.net/video-guid/thumbnail.jpg?token=tok',
        },
      ]
    end

    it 'ignores shorts that are not active' do
      create(:'course_service/short', course_id: course.id, status: 'preparation', bunny_video_id: 'video-guid')

      expect(channel_presenter.shorts).to be_empty
    end

    it 'ignores shorts without an uploaded video' do
      create(:'course_service/short', course_id: course.id, status: 'active', bunny_video_id: nil)

      expect(channel_presenter.shorts).to be_empty
    end

    it 'ignores shorts of courses from other channels' do
      other_course = create(:'course_service/course', :with_channel, skip_account_groups: true)
      create(:'course_service/short', course_id: other_course.id, status: 'active', bunny_video_id: 'video-guid')

      expect(channel_presenter.shorts).to be_empty
    end

    it 'ignores shorts of deleted courses' do
      create(:'course_service/short', course_id: course.id, status: 'active', bunny_video_id: 'video-guid')
      course.update!(deleted: true)

      expect(channel_presenter.shorts).to be_empty
    end
  end

  describe '#other_channels' do
    let(:channel) { create(:'course_service/channel') }

    it 'returns up to 4 public, non-affiliated, non-archived channels, excluding the current channel' do
      create_list(:'course_service/channel', 6)
      other = channel_presenter.other_channels.to_a

      expect(other.size).to eq 4
      expect(other).not_to include channel
      expect(other.all? {|ch| ch.public && !ch.affiliated && !ch.archived }).to be true
    end

    it 'skips hidden, affiliated or archived channels' do
      create(:'course_service/channel', public: false)
      create(:'course_service/channel', affiliated: true)
      create(:'course_service/channel', archived: true)
      visible = create(:'course_service/channel')

      other = channel_presenter.other_channels.to_a

      expect(other).to eq [visible]
    end

    it 'returns an empty relation when no other channel exists' do
      expect(channel_presenter.other_channels.to_a).to be_empty
    end
  end

  describe '#description' do
    it 'defaults to English' do
      expect(channel_presenter.description).to eq 'Test description'
    end

    context 'without description' do
      let(:channel_description) { {} }

      it 'is empty' do
        expect(channel_presenter.description).to be_empty
      end
    end
  end
end
