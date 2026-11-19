# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressPresenter do
  subject(:presenter) { described_class.build(user, course) }

  let(:course) { create(:course) }
  let(:user) { create(:'account_service/user') }

  describe '#available?' do
    subject { presenter.available? }

    context 'with empty course' do
      it { is_expected.to be_falsey }
    end

    context 'with sections' do
      before { create(:section, course:, published: true) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#sections' do
    subject { presenter.sections }

    context 'with a empty course' do
      it { is_expected.to eq [] }
    end

    context 'with sections' do
      before { create_list(:section, 2, course:, published: true) }

      its([0]) { is_expected.to be_a Course::SectionProgressPresenter }
      its([1]) { is_expected.to be_a Course::SectionProgressPresenter }
    end
  end
end
