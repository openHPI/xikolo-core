# frozen_string_literal: true

require 'spec_helper'

describe PoolEntry, type: :model do
  subject { entry }

  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:pool)       { assessment.resource_pools.find_by(purpose: 'training') }
  let(:shared_submission) { create(:shared_submission, :as_submitted, peer_assessment: assessment) }
  let(:submission) { create(:submission, user_id: SecureRandom.uuid, shared_submission:) }
  let!(:entry)     { create(:pool_entry, submission:, resource_pool: pool, available_locks: 1) }

  describe 'validity' do
    it 'is valid' do
      expect(entry).to be_valid
    end

    it 'but it should not be valid without available_locks set' do
      entry.available_locks = nil
      expect(entry).not_to be_valid
    end
  end
end
