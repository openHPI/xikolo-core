# frozen_string_literal: true

require 'spec_helper'

describe Document do
  subject(:document) { build(:'course_service/document') }

  context '(sends data to Msgr)' do
    it 'publishes an event for newly created document' do
      expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.document.create'))
      document.save
    end

    it 'publishes an event for updated document' do
      document.save

      expect(Msgr).to receive(:publish) do |updated_document_as_hash, msgr_params|
        expect(updated_document_as_hash).to be_a(Hash)
        expect(updated_document_as_hash).to include('title' => 'This awesome document')
        expect(msgr_params).to include(to: 'xikolo.course.document.update')
      end

      document.title = 'This awesome document'
      document.save
    end

    it 'publishes two events for a destroyed document' do
      document.save

      expect(Msgr).to receive(:publish) do |updated_document_as_hash, msgr_params|
        expect(updated_document_as_hash).to be_a(Hash)
        expect(updated_document_as_hash).to include('title' => document.title, 'description' => document.description)
        expect(msgr_params).to include(to: 'xikolo.course.document.update')
      end

      expect(Msgr).to receive(:publish) do |destroyed_document_as_hash, msgr_params|
        expect(destroyed_document_as_hash).to be_a(Hash)
        expect(destroyed_document_as_hash).to include('title' => document.title, 'description' => document.description)
        expect(msgr_params).to include(to: 'xikolo.course.document.destroy')
      end
      document.soft_delete
    end

    it 'sets the deleted flag for each document localization' do
      document.save
      document.destroy
      document.localizations.reload
      expect(document.localizations.map(&:deleted)).to all(be true)
    end
  end
end
