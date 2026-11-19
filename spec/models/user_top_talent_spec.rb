# frozen_string_literal: true

require 'spec_helper'

describe UserTopTalent, type: :model do
  subject(:user_top_talent) { described_class.new(user: user, source: 'admin') }

  let(:user) { create(:'account_service/user') }

  describe '(validations)' do
    it { is_expected.to accept_values_for(:source, 'admin', 'course') }

    # The enum rejects unknown values by raising on assignment; nil is allowed
    # at the model level (allow_nil) and enforced by the column's NOT NULL.
    it 'rejects an unknown source by raising on assignment' do
      expect { user_top_talent.source = 'unknown' }.to raise_error(ArgumentError, /is not a valid source/)
    end
  end

  describe '.source' do
    it { expect(described_class.source_admin).to be_a(ActiveRecord::Relation) }
    it { expect(described_class.source_course).to be_a(ActiveRecord::Relation) }
  end
end
