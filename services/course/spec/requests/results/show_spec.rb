# frozen_string_literal: true

require 'spec_helper'

describe 'Results: Show', type: :request do
  subject(:action) { api.rel(:result).get({id: result.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:result) { create(:result, dpoints: 34) }

  describe 'response' do
    it { is_expected.to respond_with :ok }

    it 'does not include shared cache headers' do
      expect(action.response.headers).not_to include('X_CACHE_XIKOLO' => 'shared')
    end
  end

  describe 'body' do
    it { is_expected.to eq 'id' => result.id, 'item_id' => result.item_id, 'user_id' => result.user_id, 'points' => 3.4 }
  end
end
