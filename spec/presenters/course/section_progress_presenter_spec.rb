# frozen_string_literal: true

require 'spec_helper'

describe Course::SectionProgressPresenter do
  subject(:presenter) do
    described_class.new(course:, section: progress, user:).tap do
      Acfs.run
    end
  end

  let(:course) { Xikolo::Course::Course.new id: SecureRandom.uuid }
  let(:progress) { Xikolo::Course::Progress.new section_progress }
  let(:section_progress) { {'kind' => 'course', 'visits' => {}, 'items' => []} }
  let(:user) { Xikolo::Account::User.new id: SecureRandom.uuid }

  describe '#available?' do
    subject { presenter.available? }

    context 'with empty course' do
      it { is_expected.to be_falsey }
    end

    context 'with not available section' do
      let(:section_progress) do
        super().merge 'available' => false
      end

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
      let(:section_progress) do
        super().merge(
          'items' => [
            {'title' => 'test'},
            {'title' => 'test2'},
          ]
        )
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
