# frozen_string_literal: true

require 'spec_helper'

describe DocumentLocalization do
  subject(:localization) { build(:document_localization, attributes) }

  let(:attributes) { {} }

  context '(sends data to Msgr)' do
    it 'publishes an event for newly created localization' do
      allow(Msgr).to receive(:publish) # The parent model also publishes events
      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.document_localization.create'))
      localization.save
    end

    it 'publishes an event for updated document' do
      localization.save

      expect(Msgr).to receive(:publish) do |updated_localization_as_hash, msgr_params|
        expect(updated_localization_as_hash).to be_a(Hash)
        expect(updated_localization_as_hash).to include('title' => 'This awesome localization')
        expect(msgr_params).to include(to: 'xikolo.course.document_localization.update')
      end

      localization.title = 'This awesome localization'
      localization.save
    end

    it 'publishes an event for a destroyed document' do
      localization.save

      expect(Msgr).to receive(:publish) do |destroyed_localization_as_hash, msgr_params|
        expect(destroyed_localization_as_hash).to be_a(Hash)
        expect(destroyed_localization_as_hash).to include('title' => localization.title, 'description' => localization.description)
        expect(msgr_params).to include(to: 'xikolo.course.document_localization.update')
      end

      expect(Msgr).to receive(:publish) do |destroyed_localization_as_hash, msgr_params|
        expect(destroyed_localization_as_hash).to be_a(Hash)
        expect(destroyed_localization_as_hash).to include('title' => localization.title, 'description' => localization.description)
        expect(msgr_params).to include(to: 'xikolo.course.document_localization.destroy')
      end
      localization.soft_delete
    end
  end

  describe '#file_url' do
    context 'without file URI' do
      let(:attributes) { {file_uri: nil} }

      it { expect(localization.file_url).to be_nil }
    end

    context 'with file URI' do
      let(:attributes) { {file_uri: 's3://xikolo-public/documents/file.png'} }

      it {
        expect(localization.file_url).to eq \
          'https://s3.xikolo.de/xikolo-public/documents/file.png'
      }
    end
  end
end
