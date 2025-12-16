# frozen_string_literal: true

require 'spec_helper'

describe 'Documents: List', type: :request do
  subject(:action) { api.rel(:documents).get(params).value! }

  let!(:document1) { create(:'course_service/document', :english, title: 'Document C') }
  let!(:document2) { create(:'course_service/document', :english, :german, title: 'Document B') }
  let!(:document3) { create(:'course_service/document', :german, title: 'Document A') }

  let(:api) { Restify.new(course_service.root_url).get.value! }

  let(:params) { {} }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(3).items }

  it 'contains all required attributes' do
    expect(action.map(&:keys)).to all(
      match_array(%w[id title description tags public localizations url localizations_url])
    )
  end

  describe '(embedding courses)' do
    let(:params) { super().merge(embed: 'course_ids') }

    it { is_expected.to all(have_key('course_ids')) }
  end

  describe '(embedding items)' do
    let(:params) { super().merge(embed: 'items') }

    it { is_expected.to all(have_key('items')) }
  end

  describe '(embedding courses and items)' do
    let(:params) { super().merge(embed: 'course_ids,items') }

    it { is_expected.to all(have_key('course_ids')) }
    it { is_expected.to all(have_key('items')) }
  end

  it 'sorts documents alphabetically by title' do
    expect(action[0]['id']).to eq document3.id
    expect(action[1]['id']).to eq document2.id
    expect(action[2]['id']).to eq document1.id
  end

  describe 'filter' do
    describe 'with empty params' do
      let(:params) { super().merge(course_id: '', item_id: '', language: '', tag: '') }

      it 'shows all documents' do
        expect(action.pluck('id')).to contain_exactly(document1.id, document2.id, document3.id)
      end
    end

    describe 'by course' do
      let(:params) { super().merge(course_id: course1.id) }
      let!(:course1) { create(:'course_service/course') }
      let!(:course2) { create(:'course_service/course') }

      before do
        document1.courses << course1
        document2.courses << course1 << course2
        document3.courses << course2
      end

      it 'shows only the documents of Course 1' do
        expect(action.pluck('id')).to contain_exactly(document1.id, document2.id)
      end
    end

    describe 'by item' do
      let(:params) { super().merge(item_id: item1.id) }
      let!(:item1) { create(:'course_service/item') }
      let!(:item2) { create(:'course_service/item') }

      before do
        document1.items << item1
        document2.items << item1 << item2
        document3.items << item2
      end

      it 'shows only the documents of Item 1' do
        expect(action.pluck('id')).to contain_exactly(document1.id, document2.id)
      end
    end

    describe 'by language' do
      let(:params) { super().merge(language: 'en') }

      it 'shows only English documents' do
        action

        expect(action.pluck('id')).to contain_exactly(document1.id, document2.id)
      end
    end

    describe 'by tag' do
      let(:params) { super().merge(tag: 'tag_a') }
      let!(:document1) { create(:'course_service/document', :with_tag_a) }
      let!(:document2) { create(:'course_service/document', :with_tag_a) }
      let(:document3) { create(:'course_service/document', :with_tag_b) }

      it 'shows only the documents of Tag A' do
        expect(action.pluck('id')).to contain_exactly(document1.id, document2.id)
      end
    end
  end
end
