# frozen_string_literal: true

require 'spec_helper'

describe TokenSigning do
  # This one will verify any string given
  let(:naive_signer) do
    Class.new do
      def sign(str)
        str.reverse
      end
    end
  end

  # This one will verify any string given
  let(:naive_verifier) do
    Class.new do
      def try_verify(str)
        str.reverse
      end
    end
  end

  # This one can not verify a single token, whatever is given
  let(:dumb_signer) do
    Class.new do
      def sign(str)
        str
      end
    end
  end

  # This one can not verify a single token, whatever is given
  let(:dumb_verifier) do
    Class.new do
      def try_verify(_str)
        nil
      end
    end
  end

  before do
    TokenSigning.register(
      :naive,
      sign: naive_signer.new,
      verify: naive_verifier.new
    )

    TokenSigning.register(
      :dumb,
      sign: dumb_signer.new,
      verify: dumb_verifier.new
    )
  end

  describe 'signing a token' do
    it 'uses the signer to sign the token' do
      expect(TokenSigning.for(:naive).sign('my_raw_token')).to eq 'nekot_war_ym'
      expect(TokenSigning.for(:dumb).sign('my_raw_token')).to eq 'my_raw_token'
    end
  end

  describe 'verifying a signed token' do
    it 'can extract the original token when the signature is valid' do
      token = TokenSigning.for(:naive).decode('nekot_war_ym')

      expect(token.valid?).to be true
      expect(token.to_s).to eq 'my_raw_token'
    end

    it 'checks for signature validity and fails when trying to access the token' do
      token = TokenSigning.for(:dumb).decode('nekot_war_ym')

      expect(token.valid?).to be false
      expect { token.to_s }.to raise_error(TokenSigning::InvalidSignature)
    end

    context 'when multiple verifiers are registered (e.g. for key rotation)' do
      it 'can extract the original token when one of the verifiers succeeds' do
        TokenSigning.register(
          :dumb,
          sign: dumb_signer.new,
          verify: TokenSigning::VerifyMultiple.new(dumb_verifier.new, naive_verifier.new)
        )

        token = TokenSigning.for(:dumb).decode('nekot_war_ym')

        expect(token.valid?).to be true
        expect(token.to_s).to eq 'my_raw_token'
      end

      it 'checks all verifiers for signature validity and fails when trying to access the token' do
        TokenSigning.register(
          :dumb,
          sign: dumb_signer.new,
          verify: TokenSigning::VerifyMultiple.new(dumb_verifier.new, dumb_verifier.new)
        )

        token = TokenSigning.for(:dumb).decode('nekot_war_ym')

        expect(token.valid?).to be false
        expect { token.to_s }.to raise_error(TokenSigning::InvalidSignature)
      end
    end
  end
end
