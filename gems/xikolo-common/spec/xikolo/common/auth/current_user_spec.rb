# frozen_string_literal: true

require 'xikolo/common/auth/current_user'

RSpec.describe Xikolo::Common::Auth::CurrentUser do
  before do
    Stub.service(
      :account,
      session_url: 'http://web.xikolo.tld/account_service/sessions/{id}{?embed,context}'
    )
  end

  let(:user_id) { '93216eb8-1a13-4079-ace8-565ef4b618b0' }
  let(:session_id) { '3d5d615b-69f1-4520-955a-126dee96a187' }
  let(:interrupts) { [] }
  let(:permissions) { [] }
  let(:session) do
    {
      id: session_id,
      user_id:,
      user: {
        id: user_id,
        anonymous:,
        preferences_url: "http://web.xikolo.tld/account_service/users/#{user_id}/preferences",
        permissions_url: "http://web.xikolo.tld/account_service/users/#{user_id}/permissions?user_id=#{user_id}",
      },
      features: {},
      permissions:,
      interrupts:,
    }
  end

  let!(:session_stub) do
    Stub.request(
      :account, :get, "/sessions/#{session_id}",
      query: {embed: 'user,permissions,features'}
    ).to_return Stub.json(
      session
    )
  end

  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      Xikolo.api(:account).value!.rel(:session).get({
        id: session_id,
        embed: 'user,permissions,features',
      }).value!
    )
  end

  let!(:preferences_stub) do
    Stub.request(
      :account, :get, "/users/#{user_id}/preferences"
    ).to_return Stub.json({
      properties: {
        'ui.video.video_player_speed': '1.3',
        'ui.video.video_player_volume': '1',
      },
    })
  end

  describe '#anonymous?' do
    subject { user.anonymous? }

    context 'anonymous user' do
      let(:anonymous) { true }
      it { is_expected.to eq(true) }
    end

    context 'authenticated user' do
      let(:anonymous) { false }
      it { is_expected.to eq(false) }
    end
  end

  describe '#authenticated?' do
    subject { user.authenticated? }

    context 'anonymous user' do
      let(:anonymous) { true }
      it { is_expected.to eq(false) }
    end

    context 'authenticated user' do
      let(:anonymous) { false }
      it { is_expected.to eq(true) }
    end
  end

  describe '#interrupt_session?' do
    subject { user.interrupt_session? }

    context 'anonymous user' do
      let(:anonymous) { true }
      it { is_expected.to eq false }
    end

    context 'authenticated user' do
      let(:anonymous) { false }
      it { is_expected.to eq false }

      context 'with interrupt' do
        let(:interrupts) { ['terms_of_service'] }
        it { is_expected.to eq true }
      end
    end
  end

  describe '#preferences' do
    subject { user.preferences.value! }

    context 'anonymous user' do
      let(:anonymous) { true }
      it { is_expected.to eq({}) }
    end

    context 'authenticated user' do
      let(:anonymous) { false }
      it { is_expected.to eq({'ui.video.video_player_speed' => '1.3', 'ui.video.video_player_volume' => '1'}) }
    end
  end

  describe '#allowed?' do
    let(:test_permission) { 'test.permission' }
    let(:anonymous) { false }

    subject { user.allowed?(test_permission) }

    context 'with permission' do
      let(:permissions) { ['test.permission'] }

      it { is_expected.to be_truthy }
    end

    context 'without permission' do
      it { is_expected.to be_falsey }
    end

    context 'in specific context' do
      let(:permissions) { ['test.permission'] }
      let(:context) { SecureRandom.uuid }

      let!(:permissions_stub) do
        WebMock.stub_request(
          :get,
          "http://web.xikolo.tld/account_service/users/#{user_id}/permissions"
        ).tap do |stub|
          stub.with(query: {user_id:, context:})
        end.to_return Stub.json(context_permissions)
      end

      subject { user.allowed?(test_permission, context:) }

      context 'with permission in context' do
        let(:context_permissions) { ['test.permission'] }

        it { is_expected.to be_truthy }
      end

      context 'without permission in context' do
        let(:context_permissions) { [] }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#allowed_any?' do
    let(:test_permissions) { ['test.permission', 'other.test.permission'] }
    let(:anonymous) { false }

    subject { user.allowed_any?(*test_permissions) }

    context 'with permission' do
      let(:permissions) { ['test.permission'] }

      it { is_expected.to be_truthy }
    end

    context 'without permission' do
      it { is_expected.to be_falsey }
    end

    context 'in specific context' do
      let(:permissions) { ['test.permission'] }
      let(:context) { SecureRandom.uuid }

      let!(:permissions_stub) do
        WebMock.stub_request(
          :get,
          "http://web.xikolo.tld/account_service/users/#{user_id}/permissions"
        ).tap do |stub|
          stub.with(query: {user_id:, context:})
        end.to_return Stub.json(context_permissions)
      end

      subject { user.allowed_any?(*test_permissions, context:) }

      context 'with permission in context' do
        let(:context_permissions) { ['test.permission'] }

        it { is_expected.to be_truthy }
      end

      context 'without permission in context' do
        let(:context_permissions) { [] }

        it { is_expected.to be_falsey }
      end
    end
  end
end
