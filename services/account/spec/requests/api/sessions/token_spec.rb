# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Show by token', type: :request do
  let(:api) { Restify.new(:test).get.value! }

  context 'user token' do
    subject { api.rel(:session).get({id: "token=#{token.token}"}).value! }

    let(:token) { create(:token) }

    let(:expected_response) do
      {'id' => nil,
       'user_agent' => nil,
       'masqueraded' => false,
       'interrupt' => false,
       'interrupts' => [],
       'user_id' => token.user.id,
       'user_url' => user_url(token.user),
       'tokens_url' => tokens_url(user_id: token.user.id),
       'self_url' => session_url("token=#{token.token}")}
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to eq expected_response }

    context 'embed user' do
      subject { api.rel(:session).get({id: "token=#{token.token}", embed: 'user'}).value! }

      let(:expected_response) do
        super().merge 'user' => json(token.user)
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq expected_response }
    end
  end

  context 'client application token' do
    subject { api.rel(:session).get({id: "token=#{token.token}"}).value! }

    let(:token) { create(:token, :with_client_application) }

    let(:expected_response) do
      {'id' => nil,
       'self_url' => session_url("token=#{token.token}")}
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to eq expected_response }

    context 'embed user' do
      subject { api.rel(:session).get({id: "token=#{token.token}", embed: 'user'}).value! }

      let(:expected_response) do
        super().merge! 'user' => nil
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.to eq expected_response }
    end
  end
end
