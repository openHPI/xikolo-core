# frozen_string_literal: true

require 'spec_helper'

describe Course::SectionProgressPresenter do
  subject(:presenter) { described_class.new(course:, section:, user:) }

  let(:course) { create(:course) }
  let(:section) { create(:section, course:, published: true, start_date: 1.day.ago, end_date: 1.day.from_now) }
  let(:user) { create(:'account_service/user') }

  describe '#available?' do
    subject { presenter.available? }

    context 'with an unpublished section' do
      let(:section) { create(:section, course:, published: false) }

      it { is_expected.to be_falsey }
    end

    context 'with available section' do
      let(:section_progress) do
        super().merge 'available' => true
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#items' do
    subject(:items) { presenter.items }

    context 'with a empty section' do
      it { is_expected.to eq [] }
    end

    context 'with items' do
      before do
        create(:item, section:, title: 'test', content_type: 'video')
        create(:item, section:, title: 'test2', content_type: 'video')
      end

      its([0]) { is_expected.to be_a ItemPresenter }
      its([1]) { is_expected.to be_a ItemPresenter }

      it 'passes the item attributes' do
        expect(items[0].title).to eq 'test'
        expect(items[1].title).to eq 'test2'
      end
    end
  end
end
