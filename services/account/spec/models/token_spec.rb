# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Token, type: :model do
  let(:token) { create(:'account_service/token') }

  describe '#Generate_token' do
    it 'generates a token' do
      expect(token.token.size).to eq 64
    end
  end
end
