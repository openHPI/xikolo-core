# frozen_string_literal: true

require 'spec_helper'

describe Course::Item, type: :model do
  let(:item) { create(:item, item_params) }
  let(:item_params) { {} }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '#fulfilled_for?' do
    subject(:item_fulfillment) { item.fulfilled_for?(user) }

    context '(items with visit-based fulfillment)' do
      let(:item_params) { {content_type: 'rich_text'} }

      it { is_expected.to be_falsey }

      context 'with visit for other user' do
        before { create(:visit, user: other_user, item:) }

        it { is_expected.to be_falsey }
      end

      context 'with visit' do
        before { create(:visit, user:, item:) }

        it { is_expected.to be_truthy }
      end
    end

    context '(items with result-based fulfillment)' do
      let(:item_params) { {content_type: 'quiz', max_dpoints: 100} }

      it { is_expected.to be_falsey }

      context 'with result for other user' do
        before { create(:result, user: other_user, item:, dpoints: 90) }

        it { is_expected.to be_falsey }
      end

      context 'with result' do
        let(:dpoints) { 10 }

        before { create(:result, user:, item:, dpoints:) }

        it { is_expected.to be_falsey }

        context 'with sufficient score' do
          let(:dpoints) { 90 }

          it { is_expected.to be_truthy }
        end

        context 'for a quiz with zero points' do
          let(:item_params) { super().merge(max_dpoints: 0) }

          it { is_expected.to be_truthy }
        end
      end
    end
  end

  describe '(content)' do
    shared_examples 'an item with polymorphic content' do
      it 'is known by its content' do
        expect(item.content.item).to eq item
      end

      it 'knows the `content_type`' do
        expect(item.content.class.polymorphic_name).to be_in %w[video lti_exercise rich_text]
        expect(item.content_type).to be_in %w[video lti_exercise rich_text]
      end
    end

    context 'with LTI exercise content' do
      subject(:item) { create(:item, :lti_exercise) }

      it_behaves_like 'an item with polymorphic content'
    end

    context 'with video content' do
      subject(:item) { create(:item, :video) }

      it_behaves_like 'an item with polymorphic content'
    end

    context 'with text content' do
      subject(:item) { create(:item, :richtext) }

      it_behaves_like 'an item with polymorphic content'
    end
  end
end
