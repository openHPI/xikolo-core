# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccountService::Token, type: :model do
  let(:token) { create(:'account_service/token') }

  describe '#Generate_token' do
    it 'generates a token' do
      expect(token.token.size).to eq 64
    end
  end

  describe 'a token per user' do
    let(:user) { create(:'account_service/user') }

    it 'stores at most one token per user' do
      create(:'account_service/token', user:)

      expect { create(:'account_service/token', user:) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows tokens without a user' do
      create(:'account_service/token')
      create(:'account_service/token')

      expect(described_class.count).to be > 1
    end
  end
end
