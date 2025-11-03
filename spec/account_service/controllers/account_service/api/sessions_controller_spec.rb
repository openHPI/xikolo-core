# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::SessionsController, type: :controller do
  include_context 'account_service API controller'
  let(:user)    { create(:'account_service/user', password: 'secret123') }
  let(:session) { create(:'account_service/session') }
  let(:params)  { {} }
  let(:json)    { JSON.parse response.body }

  describe '#index' do
    subject(:response) { get :index, params: {user_id: user.id} }

    it { is_expected.to have_http_status :ok }
  end

  describe '#show' do
    subject(:response) { get :show, params: {id: record.id} }

    let(:record) { create(:'account_service/session') }

    it { is_expected.to have_http_status :ok }

    describe 'Header: Cache-Control' do
      subject(:cache_config) { response.headers['Cache-Control'].split(/[\s,]+/) }

      it do
        pending 'Figure out why this is null!!!!'

        expect(cache_config).to include 'private'
      end
    end

    describe 'JSON' do
      subject { json }

      it { is_expected.not_to eq record.as_json }
      it { is_expected.to eq AccountService::SessionDecorator.new(record).as_json }
    end

    context 'with anonymous session' do
      let(:response) { get :show, params: {id: 'anonymous'} }

      describe 'Header: Cache-Control' do
        subject { response.headers['Cache-Control'].split(/[\s,]+/) }

        it { is_expected.to include 'public' }
        it { is_expected.to include 'max-age=60' }
      end

      describe 'Header: Vary' do
        subject { response.headers['Vary'].split(/[\s,]+/) }

        it { is_expected.to match_array %w[Accept Host] }
      end
    end
  end

  describe '#destroy' do
    subject(:response) { delete :destroy, params: {id: session.id} }

    it { is_expected.to have_http_status :ok }
  end
end
