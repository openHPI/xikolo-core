# frozen_string_literal: true

require 'spec_helper'

describe RestifyPaginationCollection do
  subject(:collection) { described_class.new(restify_collection) }

  let(:restify_collection) { instance_double(Restify::Resource, response:) }
  let(:response) { instance_double(Restify::Response, headers:) }
  let(:headers) do
    {
      'X_TOTAL_PAGES' => '5',
      'X_CURRENT_PAGE' => '3',
      'X_TOTAL_COUNT' => '47',
      'X_PER_PAGE' => '10',
    }
  end

  describe '#total_pages' do
    it { expect(collection.total_pages).to eq 5 }
  end

  describe '#current_page' do
    it { expect(collection.current_page).to eq 3 }
  end

  describe '#total_entries' do
    it { expect(collection.total_entries).to eq 47 }
  end

  describe '#per_page' do
    it { expect(collection.per_page).to eq 10 }
  end

  describe '#offset' do
    it 'returns the number of records to skip to reach the current page' do
      expect(collection.offset).to eq 20
    end

    context 'on the first page' do
      let(:headers) { super().merge('X_CURRENT_PAGE' => '1') }

      it { expect(collection.offset).to eq 0 }
    end
  end
end
