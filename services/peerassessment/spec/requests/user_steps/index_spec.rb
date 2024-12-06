# frozen_string_literal: true

require 'spec_helper'

describe 'User Steps: Index', type: :request do
  subject(:index) { assessment_resource.rel(:user_steps).get(params).value! }

  let!(:assessment) { create(:peer_assessment, :with_steps) }
  let(:user_id) { SecureRandom.uuid }

  let(:service_resource) { Restify.new(:test).get.value! }
  let(:assessment_resource) { service_resource.rel(:peer_assessment).get(id: assessment.id).value! }

  context 'without a user ID' do
    let(:params) { {} }

    it 'responds with 422 Unprocessable Entity' do
      expect { index }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
      end
    end
  end

  context 'with an invalid user ID' do
    let(:params) { {user_id:} }

    it 'responds with 404 Not Found' do
      expect { index }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  context 'with a valid user ID' do
    let(:params) { {user_id:} }

    before { create(:participant, peer_assessment_id: assessment.id, user_id:) }

    it { is_expected.to respond_with :ok }

    it 'lists all five steps' do
      expect(index.size).to eq 5
    end
  end
end
