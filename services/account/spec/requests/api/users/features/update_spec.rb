# frozen_string_literal: true

require 'spec_helper'

describe 'Users: Features: Merge', type: :request do
  subject(:resource) { base.rel(:features).patch(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:user).get(id: user).value! }
  let(:user) { create(:user) }
  let!(:feature) { create(:feature, owner: user) }

  context 'with new flipper' do
    let(:params) { {'new.flipper' => 'On Sale now!'} }

    before { expect(params.keys.first).not_to eq feature.name }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'responds with features' do
      expect(resource).to eq Feature.all.decorate.as_json
    end
  end

  context 'with existing feature' do
    let(:params) { {feature.name => 'On Sale now!'} }

    before { expect(params.values.first).not_to eq feature.value }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'updates existing feature' do
      expect { resource }.to change { feature.reload.value }.from(feature.value).to(params.values.first)
    end

    it 'responds with features' do
      expect(resource).to eq Feature.all.decorate.as_json
    end
  end

  context 'with multiple features' do
    let(:params) do
      {feature.name => 'On Sale now!',
       'dr.flipps' => 'Astromedical'}
    end

    before { create(:feature, owner: user) }

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'updates existing feature' do
      expect { resource }.to change { feature.reload.value }.from(feature.value).to(params[feature.name])
    end

    it 'creates new feature' do
      expect { resource }.to change {
        Feature.where(name: 'dr.flipps', value: 'Astromedical').count
      }.from(0).to(1)
    end

    it 'responds with list of features' do
      expect(resource).to eq Feature.all.decorate.as_json
    end

    context 'with invalid feature' do
      let(:params) { super().merge 'feature.with.empty.value' => '' }

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
        end.not_to change Feature, :count
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
