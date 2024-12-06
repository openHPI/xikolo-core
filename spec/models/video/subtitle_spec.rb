# frozen_string_literal: true

require 'spec_helper'

describe Video::Subtitle, type: :model do
  let(:video) { create(:video) }
  let(:params) { attributes_for(:video_subtitle).merge(video:) }
  let(:subtitle) { build(:video_subtitle, params) }

  describe '(validations)' do
    subject(:the_sub) { subtitle }

    it { is_expected.not_to accept_values_for(:video, nil) }
    it { is_expected.not_to accept_values_for(:lang, '') }
  end

  context 'with existing subtitles in the given language' do
    subject(:invalid_subtitle) { described_class.create params }

    before { described_class.create! params }

    it 'does not create the subtitles' do
      expect(invalid_subtitle).not_to be_valid
    end
  end

  describe '.extract_lang' do
    subject(:lang) { described_class.extract_lang filename }

    let(:filename) { 'subtitle-en.vtt' }

    it 'extracts the correct language' do
      expect(lang).to eq 'en'
    end

    context 'with an invalid filename' do
      let(:filename) { 'subtitle.vtt' }

      it 'returns false' do
        expect(lang).to be_falsey
      end
    end

    context 'with OS X archive metadata files' do
      let(:filename) { '__MACOSX_subtitle-en.vtt' }

      it 'returns false' do
        expect(lang).to be_falsey
      end
    end

    context 'with a 3-letter language code' do
      let(:filename) { 'subtitle-tet.vtt' }

      it 'extracts the correct language' do
        expect(lang).to eq 'tet'
      end
    end
  end

  describe '#create_cues!' do
    subject(:create_cues) { subtitle.create_cues!(blob) }

    let(:subtitle) { create(:video_subtitle) }
    let(:blob) { file.read }

    context 'without any provided file' do
      let(:blob) { nil }

      it { expect(create_cues).to be_nil }
    end

    context 'with a valid VTT file' do
      let(:file) { Rails.root.join('spec/support/files/video/subtitles/valid_en.vtt').open }

      it { expect { create_cues }.to change { subtitle.reload.cues.count }.from(0).to(3) }
    end

    context 'with a VTT file containing blank spaces' do
      let(:file) { Rails.root.join('spec/support/files/video/subtitles/with_blank_spaces_en.vtt').open }

      it { expect { create_cues }.to change { subtitle.reload.cues.count }.from(0).to(3) }
    end

    context 'with an empty VTT file' do
      let(:file) { Rails.root.join('spec/support/files/video/subtitles/empty-en.vtt').open }

      it { expect(create_cues).to be_nil }
    end

    context 'with an invalid VTT file' do
      let(:file) { Rails.root.join('spec/support/files/video/subtitles/invalid_en.vtt').open }

      it 'raises an error and does not create subtitle cues' do
        expect { create_cues }.to raise_error(Video::InvalidSubtitleError) do |error|
          expect(error.message).to eq 'invalid_subtitle'
          expect(error.identifiers).to eq [1]
          expect(subtitle.reload.cues.count).to be_zero
        end
      end
    end

    context 'with an invalid VTT file containing multiple invalid cues' do
      let(:file) { Rails.root.join('spec/support/files/video/subtitles/multiple_invalid_en.vtt').open }

      it 'raises an error and does not create subtitle cues' do
        expect { create_cues }.to raise_error(Video::InvalidSubtitleError) do |error|
          expect(error.message).to eq 'invalid_subtitle'
          expect(error.identifiers).to eq [1, 2]
          expect(subtitle.reload.cues.count).to be_zero
        end
      end
    end
  end
end
