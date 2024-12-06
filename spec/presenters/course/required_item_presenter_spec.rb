# frozen_string_literal: true

require 'spec_helper'

describe Course::RequiredItemPresenter do
  subject(:presenter) { described_class.new(item, current_user) }

  let(:item) { create(:item, item_params) }
  let(:item_params) { {content_type: 'rich_text'} }
  let(:user) { create(:user) }
  let(:visit) { create(:visit, item:, user:) }
  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      {
        'user_id' => user.id,
        'user' => {
          'anonymous' => false,
        },
      }
    )
  end

  describe '.requirements_for' do
    subject(:required_items) { described_class.requirements_for(item_with_requirements, current_user) }

    let(:item_with_requirements) do
      create(:item, required_item_ids: [item.id])
    end

    it 'yields a list of required items' do
      expect(required_items).to be_an(Array)
      expect(required_items.first).to be_a(Course::RequiredItemPresenter)
      expect(required_items.first.id).to eq item.id
    end
  end

  describe '#id' do
    subject { presenter.id }

    it { is_expected.to eq item.id }
  end

  describe '#title' do
    subject { presenter.title }

    it { is_expected.to eq item.title }
  end

  describe '#course_code' do
    subject { presenter.course_code }

    it { is_expected.to eq item.section.course.course_code }
  end

  describe '#fulfilled?' do
    subject { presenter.fulfilled? }

    it { is_expected.to be_falsey }

    context 'with item visit' do
      before { visit }

      it { is_expected.to be_truthy }
    end
  end

  describe '#icon' do
    subject { presenter.icon }

    it { is_expected.to eq 'circle-xmark' }

    context 'with item visit' do
      before { visit }

      it { is_expected.to eq 'circle-check' }
    end
  end

  describe '#hint' do
    subject { presenter.hint }

    it { is_expected.to eq 'Visit this learning unit and work through the content.' }

    context 'with result-based item' do
      let(:item_params) { {content_type: 'quiz'} }

      it { is_expected.to eq 'Complete this learning unit with a score of at least 50% of the maximum points.' }
    end

    context 'with fulfilled requirement' do
      before { visit }

      it { is_expected.to be_falsey }
    end
  end
end
