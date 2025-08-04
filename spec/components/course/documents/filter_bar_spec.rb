# frozen_string_literal: true

require 'spec_helper'

describe Course::Documents::FilterBar, type: :component do
  subject(:component) do
    with_request_url '/courses/123/documents' do
      render_inline described_class.new(documents)
    end
  end

  let(:documents) do
    [
      {
        title: 'Document A',
        description: 'Description A',
        tags: ['Tag A', 'Tag B'],
        localizations: [{language: 'en'}],
      },
      {
        title: 'Document B',
        description: 'Description B',
        tags: ['Tag A', 'Tag B'],
        localizations: [{language: 'de'}],
      },
    ]
  end

  describe 'filters' do
    it 'displays all available language options' do
      expect(component).to have_select 'Language', text: "All\nEnglish (English)\nGerman (Deutsch)"
    end

    context 'in a different platform language' do
      subject(:localized_component) do
        I18n.with_locale(:de) do
          with_request_url '/courses/123/documents' do
            render_inline(described_class.new(documents))
          end
        end
      end

      it 'localizes the language filter' do
        expect(localized_component).to have_select 'Sprache', text: "Alle\nEnglisch (English)\nDeutsch (Deutsch)"
      end
    end

    it 'displays all available tag options' do
      expect(component).to have_select 'Tags', text: "All\nTag A\nTag B"
    end

    context 'with no tags present' do
      let(:documents) do
        [
          {
            title: 'Document A',
            description: 'Description A',
            localizations: [{language: 'en'}],
          },
          {
            title: 'Document B',
            description: 'Description B',
            localizations: [{language: 'de'}],
          },
        ]
      end

      it 'does not display the tag filter' do
        expect(component).to have_no_select 'Tags'
        expect(component).to have_select 'Language', text: "All\nEnglish (English)\nGerman (Deutsch)"
      end
    end
  end
end
