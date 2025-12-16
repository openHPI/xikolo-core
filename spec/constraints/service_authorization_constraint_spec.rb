# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceAuthorizationConstraint do
  subject(:constraint) { described_class.new(token) }

  let(:token) { 'supersecret123' } # normally ENV value
  let(:request) { instance_double(ActionDispatch::Request, get_header: header_value) }

  describe '#matches?' do
    context 'when Authorization header is missing' do
      let(:header_value) { nil }

      it 'returns false' do
        expect(constraint.matches?(request)).to be(false)
      end
    end

    context 'when Authorization header does not start with "Bearer "' do
      let(:header_value) { 'Token something' }

      it 'returns false' do
        expect(constraint.matches?(request)).to be(false)
      end
    end

    context 'when Authorization header contains an incorrect token' do
      let(:header_value) { 'Bearer wrongtoken' }

      it 'returns false' do
        expect(constraint.matches?(request)).to be(false)
      end
    end

    context 'when Authorization header contains the correct token' do
      let(:header_value) { "Bearer #{token}" }

      it 'returns true' do
        expect(constraint.matches?(request)).to be(true)
      end
    end
  end
end
