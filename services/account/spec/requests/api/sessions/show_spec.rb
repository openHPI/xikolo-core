# frozen_string_literal: true

require 'spec_helper'

describe 'Sessions: Show', type: :request do
  subject(:resource) { api.rel(:session).get({id: session}).value! }

  let(:api) { Restify.new(:test, **config).get.value! }
  let(:config) { {} }
  let(:session) { create(:session, access_at: Time.zone.yesterday) }
  let(:masqueraded_user) { create(:user) }

  let(:session_resource) do
    {
      'id' => session.id,
      'user_id' => session.user_id,
      'user_agent' => nil,
      'masqueraded' => false,
      'interrupt' => false,
      'interrupts' => [],
      'self_url' => session_url(session),
      'user_url' => user_url(session.user),
      'masquerade_url' => session_masquerade_url(session),
      'tokens_url' => tokens_url(user_id: session.user.id),
    }
  end

  it { is_expected.to respond_with :ok }

  it 'responds with session resource' do
    expect(resource).to eq session_resource
  end

  describe 'access date' do
    around {|example| Timecop.freeze(&example) }

    it 'updates the session access date' do
      resource
      expect(session.reload.access_at).to eq(Time.zone.today)
    end

    it 'updates the user\'s last access date' do
      resource
      expect(session.user.reload.last_access).to eq(Time.zone.today)
    end

    context 'when masqueraded' do
      before { session.masquerade! masqueraded_user }

      it 'does not update the session access date' do
        resource
        expect(session.reload.access_at).to eq(Time.zone.yesterday)
      end
    end
  end

  describe 'interrupt' do
    context 'by default' do
      it { expect(resource['interrupt']).to be false }
      it { expect(resource['interrupts']).to eq [] }
    end

    context 'treatment/consent interrupt' do
      let!(:treatments) { create_list(:treatment, 2) }

      before do
        create(:consent, user: session.user, treatment: treatments[0])
        create(:consent, user: session.user, treatment: treatments[1], value: false)
      end

      it { expect(resource['interrupt']).to be false }
      it { expect(resource['interrupts']).to eq [] }

      context 'with new treatment' do
        before { create(:treatment) }

        it { expect(resource['interrupt']).to be true }
        it { expect(resource['interrupts']).to eq ['new_consents'] }
      end
    end

    context 'policy interrupt' do
      context 'with new policy' do
        before { create(:policy) }

        it { expect(resource['interrupt']).to be true }
        it { expect(resource['interrupts']).to eq ['new_policy'] }
      end
    end

    context 'with incomplete profile' do
      let(:session) { create(:session, user: create(:user, completed_profile: false)) }

      it { expect(resource['interrupt']).to be true }
      it { expect(resource['interrupts']).to eq ['mandatory_profile_fields'] }
    end
  end

  describe 'when masqueraded' do
    before { session.masquerade! masqueraded_user }

    it { expect(resource['masqueraded']).to be true }
    it { expect(resource['user_id']).to eq masqueraded_user.id }
  end

  describe 'invalid session ID' do
    it 'responds with 404 Not Found (I)' do
      expect do
        api.rel(:session).get({id: 'token=abc'}).value!
      end.to raise_error Restify::NotFound
    end

    it 'responds with 404 Not Found (II)' do
      expect do
        api.rel(:session).get({id: '1'}).value!
      end.to raise_error Restify::NotFound
    end
  end

  describe 'anonymous' do
    subject(:resource) { api.rel(:session).get({id: 'anonymous'}).value! }

    it 'responds with anonymous session' do
      expect(resource).to eq \
        'id' => nil,
        'user_id' => User.anonymous.id,
        'user_agent' => nil,
        'masqueraded' => false,
        'interrupt' => false,
        'interrupts' => [],
        'self_url' => session_url('anonymous'),
        'user_url' => user_url(User.anonymous)
    end

    it { is_expected.to include_header 'Cache-Control' => 'max-age=60, public' }
    it { is_expected.to include_header 'Vary' => 'Accept, Host' }

    context 'with embedded permissions and features' do
      subject(:resource) do
        api.rel(:session)
          .get({id: 'anonymous', embed: 'features,permissions'})
          .value!
      end

      it { expect(resource['features']).to eq({}) }
      it { expect(resource['permissions']).to eq [] }
    end
  end

  describe '?embed' do
    context 'user' do
      subject(:resource) do
        api.rel(:session).get({id: session, embed: 'user'}).value!
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.not_to include_header 'x-cache-xikolo' => 'shared' }

      it 'includes user resource' do
        expect(resource['user']).to eq json(session.user)
      end

      context 'when masqueraded' do
        before { session.masquerade! masqueraded_user }

        it { expect(resource['user']).to eq json(masqueraded_user) }
      end
    end

    context 'features' do
      subject(:resource) do
        api.rel(:session).get({id: session, embed: 'features'}).value!
      end

      let(:groups) { create_list(:group, 5) }

      before do
        groups.map {|group| create_list(:feature, 4, owner: group) }.flatten

        session.user.memberships.create! group: groups[2]
        session.user.memberships.create! group: groups[3]
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.not_to include_header 'x-cache-xikolo' => 'shared' }

      it 'includes feature map' do
        expect(resource['features']).to match_array json \
          Feature.where owner: [groups[2], groups[3], session.user]
      end

      context 'when masqueraded' do
        before do
          session.masquerade! masqueraded_user
          masqueraded_user.memberships.create! group: groups[2]
        end

        it do
          expect(resource['features']).to match_array json \
            Feature.where owner: [groups[2], session.user]
        end
      end
    end

    context 'permissions' do
      subject(:resource) do
        api.rel(:session).get({id: session, embed: 'permissions'}).value!
      end

      it { is_expected.to respond_with :ok }
      it { is_expected.not_to include_header 'x-cache-xikolo' => 'shared' }

      it { is_expected.to have_key 'permissions' }

      describe '[permissions]' do
        subject { resource['permissions'] }

        let(:resource) do
          api.rel(:session)
            .get({id: session, embed: 'permissions', context: request_context})
            .value!
        end

        let(:user) { session.user }

        include_examples 'shared:permissions'
      end
    end
  end

  describe '?context' do
    subject(:resource) do
      api.rel(:session)
        .get({id: session, embed: 'permissions', context:})
        .value!
    end

    let(:roles) { create_list(:role, 2) }
    let(:group) { create(:group) }
    let(:context) { create(:context) }

    before do
      session.user.groups << group

      create(:grant,
        principal: group, role: roles[0], context:)

      create(:grant,
        principal: session.user, role: roles[1], context: Context.root)
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.not_to include_header 'x-cache-xikolo' => 'shared' }

    it 'includes permissions' do
      expect(resource['permissions']).to \
        eq roles.map(&:permissions).flatten.sort
    end

    context 'with root context' do
      subject(:resource) do
        api.rel(:session)
          .get({id: session, embed: 'permissions', context: 'root'})
          .value!
      end

      it { is_expected.to respond_with :ok }
      it { expect(resource['permissions']).to match_array roles[1].permissions }
    end
  end
end
