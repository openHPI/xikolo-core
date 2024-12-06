# frozen_string_literal: true

require 'spec_helper'

describe 'Show email', type: :request do
  subject(:resource) { api.rel(:email).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }
  let!(:record) { create(:email, address: 'john@example.org') }

  context 'with email UUID' do
    let(:params) { {id: record.uuid} }

    it { is_expected.to eq json(record) }
  end

  context 'with email address' do
    let(:params) { {id: 'john@example.org'} }

    it { is_expected.to eq json(record) }
  end

  context 'with wrong case' do
    let(:params) { {id: 'JOHN@Example.Org'} }

    it { is_expected.to eq json(record) }
  end

  context 'with non-existing email address' do
    let(:params) { {id: 'a.b/c+d-e@g-h.i.j'} }

    it 'responds with 404 Not Found' do
      expect { resource }.to raise_error Restify::ClientError do |err|
        expect(err.status).to eq :not_found
      end
    end
  end
end
