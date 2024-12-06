# frozen_string_literal: true

require 'spec_helper'

describe TokenSigning::Paseto do
  # Hand-generated pair of matching keys
  let(:private_key) { 'Fg20p95f_8DmL3SgQhnyZpbE9dYUjlP38uncWVwnW1I' }
  let(:public_key) { 'fe3BIEgJRIsZz4dWT29wGF85knpAwJg0-NQB1f4PJu0' }

  before do
    TokenSigning.register(
      :paseto,
      sign: TokenSigning::Paseto::Sign.new(private_key),
      verify: TokenSigning::Paseto::Verify.new(public_key)
    )
  end

  it 'can verify a token it signed' do
    token = TokenSigning.for(:paseto).sign('this_was_signed')

    expect(TokenSigning.for(:paseto).decode(token).to_s).to eq 'this_was_signed'
  end

  it 'errors on a token it did not sign' do
    expect do
      TokenSigning.for(:paseto).decode('this_was_not_signed').to_s
    end.to raise_error(TokenSigning::InvalidSignature)
  end
end
