# frozen_string_literal: true

require 'spec_helper'

describe Course::Result, type: :model do
  let(:user) { create(:user) }
  let(:item) { create(:item) }

  before do
    create_list(:result, 2, item:, user:, dpoints: 1)
    # best result
    create(:result, item:, user:, dpoints: 100)
    # result for different item
    create(:result, user:, dpoints: 200)
  end

  describe '#best_for' do
    subject(:best_result) { Course::Result.best_for(item, user) }

    it 'is the correct result' do
      expect(best_result.dpoints).to eq 100
    end
  end
end
