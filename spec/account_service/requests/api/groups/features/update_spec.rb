# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Features: Merge', type: :request do
  subject(:resource) { base.rel(:features).patch(data).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }
  let(:group) { create(:'account_service/group') }
  let!(:feature) { create(:'account_service/feature', owner: group) }

  context 'with new flipper' do
    let(:data) { {'new.flipper' => 'On Sale now!'} }

    before { expect(data.keys.first).not_to eq feature.name }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'responds with features' do
      expect(resource).to eq AccountService::Feature.where(owner: group).decorate.as_json
    end
  end

  context 'with existing feature' do
    let(:data) { {feature.name => 'On Sale now!'} }

    before { expect(data.values.first).not_to eq feature.value }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'updates existing feature' do
      expect { resource }.to change { feature.reload.value }.from(feature.value).to(data.values.first)
    end

    it 'responds with features' do
      expect(resource).to eq AccountService::Feature.where(owner: group).decorate.as_json
    end
  end

  context 'with multiple features' do
    let(:data) do
      {feature.name => 'On Sale now!',
       'dr.flipps' => 'Astromedical'}
    end

    before { create(:'account_service/feature', owner: group) }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'updates existing feature' do
      expect { resource }.to change { feature.reload.value }.from(feature.value).to(data[feature.name])
    end

    it 'creates new feature' do
      expect { resource }.to change {
        AccountService::Feature.where(name: 'dr.flipps', value: 'Astromedical').count
      }.from(0).to(1)
    end

    it 'responds with list of features' do
      expect(resource).to eq AccountService::Feature.where(owner: group).decorate.as_json
    end

    context 'with invalid feature' do
      let(:data) { super().merge 'feature.with.empty.value' => '' }

      it 'responds with Unprocessable Entity' do
        expect { resource }.to raise_error Restify::ClientError do |error|
          expect(error.status).to eq :unprocessable_content
          expect(error.errors).to eq 'value' => ['required']
        end
      end

      it 'does not create new features' do
        expect do
          resource
        rescue StandardError
          Restify::ClientError
        end.not_to change AccountService::Feature, :count
      end

      it 'does not change feature' do
        expect do
          resource
        rescue StandardError
          Restify::ClientError
        end.not_to change(feature, :reload)
      end
    end
  end
end
