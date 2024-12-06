# frozen_string_literal: true

require 'spec_helper'

describe ResourcePool, type: :model do
  subject { pool }

  let(:assessment) { create(:peer_assessment, :with_steps) }
  let!(:pool)      { create(:resource_pool, peer_assessment_id: assessment.id, purpose: 'review') }

  describe 'validity' do
    it 'is valid' do
      expect(pool).to be_valid
    end

    it 'but it should not be valid without puropse set' do
      pool.purpose = nil
      expect(pool).not_to be_valid
    end
  end

  describe '.initial_locks' do
    it 'is three for a review pool' do
      expect(pool.initial_locks).to eq(3)
    end

    it 'is one for a train pool' do
      pool.purpose = 'training'
      pool.save!

      expect(pool.reload.initial_locks).to eq(1)
    end
  end
end
