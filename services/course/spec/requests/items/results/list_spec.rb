# frozen_string_literal: true

require 'spec_helper'

describe 'Item Results: List', type: :resource do
  subject(:resource) { item_api.rel(:results).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:item_api) { api.rel(:item).get(id: item.id).value! }
  let!(:item) { create(:item) }

  let(:params) { {} }

  before { create_list(:result, 3, item:) }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(3).items }

  it 'contains all required attributes' do
    expect(resource.map(&:keys)).to all(
      match_array(%w[id user_id item_id points])
    )
  end

  describe 'with best_per_user=true' do
    let(:params) { super().merge(best_per_user: true) }

    it { is_expected.to have(3).items }

    context 'with two more results, both for the same user' do
      let(:user_id) { generate(:user_id) }
      let!(:good_result) { create(:result, item:, user_id:, dpoints: 300) }
      let!(:bad_result) { create(:result, item:, user_id:, dpoints: 50) }

      it { is_expected.to have(4).items }

      it 'only returns the good result, but not the bad one' do
        ids = resource.pluck('id')
        expect(ids).to include(good_result.id)
        expect(ids).not_to include(bad_result.id)
      end
    end
  end

  describe 'by user ID' do
    let(:params) { super().merge(user_id:) }
    let(:user_id) { generate(:user_id) }

    let!(:good_result) { create(:result, item:, user_id:, dpoints: 300) }
    let!(:bad_result) { create(:result, item:, user_id:, dpoints: 50) }

    it "only returns the user's results" do
      ids = resource.pluck('id')
      expect(ids).to contain_exactly(good_result.id, bad_result.id)
    end

    context 'with best_per_user=true' do
      let(:params) { super().merge(best_per_user: true) }

      it "only returns the user's best result" do
        expect(resource.count).to eq 1
        expect(resource.first['id']).to eq good_result.id
      end
    end
  end
end
