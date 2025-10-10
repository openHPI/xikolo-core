# frozen_string_literal: true

require 'spec_helper'

describe 'List user consents', type: :request do
  subject(:resource) { base.rel(:consents).patch(data).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }

  let(:user) { create(:'account_service/user') }

  let(:data) { {} }
  let!(:treatments) { create_list(:'account_service/treatment', 3) }
  let!(:consent) { create(:'account_service/consent', user:, treatment: treatments[1]) }

  around {|e| Timecop.freeze(&e) }

  it 'responds with status OK' do
    expect(resource).to respond_with :ok
  end

  it 'responds with consent list' do
    expect(resource.size).to eq 3

    expect(resource[0]).to match \
      'name' => treatments[0].name,
      'required' => treatments[0].required,
      'consented' => nil,
      'self_url' => account_service.user_consent_url(user, treatments[0])

    expect(resource[1]).to match \
      'name' => treatments[1].name,
      'required' => treatments[1].required,
      'consented' => true,
      'consented_at' => consent.consented_at.iso8601(0),
      'self_url' => account_service.user_consent_url(user, treatments[1])

    expect(resource[2]).to match \
      'name' => treatments[2].name,
      'required' => treatments[2].required,
      'consented' => nil,
      'self_url' => account_service.user_consent_url(user, treatments[2])
  end

  context 'with ID-based list update' do
    let(:treatment) { treatments[0] }

    let(:data) do
      [{id: treatment.id, consented: true}]
    end

    it 'creates consent record' do
      expect { resource }.to change { user.consents.reload.count }.from(1).to(2)

      user.consents.where(treatment:).take!.tap do |consent|
        expect(consent.consented).to be true
      end
    end

    it 'responds with updated consent list' do
      expect(resource.size).to eq 3

      expect(resource[0]).to match \
        'name' => treatments[0].name,
        'required' => treatments[0].required,
        'consented' => true,
        'consented_at' => Time.now.utc.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[0])

      expect(resource[1]).to match \
        'name' => treatments[1].name,
        'required' => treatments[1].required,
        'consented' => true,
        'consented_at' => consent.consented_at.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[1])

      expect(resource[2]).to match \
        'name' => treatments[2].name,
        'required' => treatments[2].required,
        'consented' => nil,
        'self_url' => account_service.user_consent_url(user, treatments[2])
    end

    it 'creates a membership for the feature group' do
      expect { resource }.to change { treatment.group.members.count }.by(1)
      expect(treatment.group.members).to include(user)
    end
  end

  context 'with name-based list update' do
    let(:treatment) { treatments[0] }

    let(:data) do
      [{name: treatment.name, consented: true}]
    end

    it 'creates consent record' do
      expect { resource }.to change { user.consents.reload.count }.from(1).to(2)

      user.consents.where(treatment:).take!.tap do |consent|
        expect(consent.consented).to be true
      end
    end

    it 'responds with updated consent list' do
      expect(resource.size).to eq 3

      expect(resource[0]).to match \
        'name' => treatments[0].name,
        'required' => treatments[0].required,
        'consented' => true,
        'consented_at' => Time.now.utc.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[0])

      expect(resource[1]).to match \
        'name' => treatments[1].name,
        'required' => treatments[1].required,
        'consented' => true,
        'consented_at' => consent.consented_at.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[1])

      expect(resource[2]).to match \
        'name' => treatments[2].name,
        'required' => treatments[2].required,
        'consented' => nil,
        'self_url' => account_service.user_consent_url(user, treatments[2])
    end

    it 'creates a membership for the feature group' do
      expect { resource }.to change { treatment.group.members.count }.by(1)
      expect(treatment.group.members).to include(user)
    end
  end

  context 'with multiple updates' do
    let(:data) do
      [{id: treatments[0].id, consented: true},
       {name: treatments[2].name, consented: true}]
    end

    it 'creates consent record' do
      expect { resource }.to change { user.consents.reload.count }.from(1).to(3)

      user.consents.where(treatment: treatments[0]).take!.tap do |consent|
        expect(consent.consented).to be true
      end

      user.consents.where(treatment: treatments[2]).take!.tap do |consent|
        expect(consent.consented).to be true
      end
    end

    it 'responds with updated consent list' do
      expect(resource.size).to eq 3

      expect(resource[0]).to match \
        'name' => treatments[0].name,
        'required' => treatments[0].required,
        'consented' => true,
        'consented_at' => Time.now.utc.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[0])

      expect(resource[1]).to match \
        'name' => treatments[1].name,
        'required' => treatments[1].required,
        'consented' => true,
        'consented_at' => consent.consented_at.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[1])

      expect(resource[2]).to match \
        'name' => treatments[2].name,
        'required' => treatments[2].required,
        'consented' => true,
        'consented_at' => Time.now.utc.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[2])
    end

    it 'creates a membership for the feature groups' do
      expect { resource }.to change(Membership, :count).by(2)
      expect(treatments[0].group.members).to include(user)
      expect(treatments[2].group.members).to include(user)
    end
  end

  context 'with denied consent' do
    let(:treatment) { treatments[0] }

    let(:data) do
      [{id: treatment.id, consented: false}]
    end

    it 'creates consent record' do
      expect { resource }.to change { user.consents.reload.count }.from(1).to(2)

      user.consents.where(treatment:).take!.tap do |consent|
        expect(consent.consented).to be false
      end
    end

    it 'responds with updated consent list' do
      expect(resource.size).to eq 3

      expect(resource[0]).to match \
        'name' => treatments[0].name,
        'required' => treatments[0].required,
        'consented' => false,
        'consented_at' => Time.now.utc.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[0])

      expect(resource[1]).to match \
        'name' => treatments[1].name,
        'required' => treatments[1].required,
        'consented' => true,
        'consented_at' => consent.consented_at.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[1])

      expect(resource[2]).to match \
        'name' => treatments[2].name,
        'required' => treatments[2].required,
        'consented' => nil,
        'self_url' => account_service.user_consent_url(user, treatments[2])
    end

    it 'does not create a membership for the feature group' do
      expect { resource }.not_to change { treatment.group.members.count }
      expect(treatment.group.members).not_to include(user)
    end
  end

  context 'with revocation' do
    let(:data) do
      [{id: consent.treatment.id, consented: false}]
    end

    it 'does not destroy a consent resource' do
      expect { resource }.not_to change { user.consents.reload.count }
    end

    it 'responds with updated consent list' do
      expect(resource.size).to eq 3

      expect(resource[0]).to match \
        'name' => treatments[0].name,
        'required' => treatments[0].required,
        'consented' => nil,
        'self_url' => account_service.user_consent_url(user, treatments[0])

      expect(resource[1]).to match \
        'name' => treatments[1].name,
        'required' => treatments[1].required,
        'consented' => false,
        'consented_at' => consent.consented_at.iso8601(0),
        'self_url' => account_service.user_consent_url(user, treatments[1])

      expect(resource[2]).to match \
        'name' => treatments[2].name,
        'required' => treatments[2].required,
        'consented' => nil,
        'self_url' => account_service.user_consent_url(user, treatments[2])
    end

    it 'deletes the membership for the Treatment group' do
      expect { resource }.to change { consent.treatment.group.members.count }.by(-1)
      expect(consent.treatment.group.members).not_to include(user)
    end
  end
end
