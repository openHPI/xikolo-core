# frozen_string_literal: true

require 'spec_helper'

describe MetricsController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:user_id) { '00000001-3100-4444-9999-000000000003' }
  let!(:metric) { create(:metric) }

  describe 'GET index' do
    subject { response }

    let(:params) { {} }
    let(:action) { get :index, params: }

    it 'renders all metrics' do
      action
      expect(json.pluck('id')).to contain_exactly(metric.id)
    end

    context 'for user_test' do
      let(:params) { {user_test_id: user_test.id} }
      let(:user_test) { create(:user_test) }
      let!(:metric_2) { user_test.metrics.first }

      it 'renders all metrics of the user test' do
        action
        expect(json.pluck('id')).to contain_exactly(metric_2.id)
      end
    end
  end

  describe 'GET show' do
    let(:action) { get :show, params: {id: metric.to_param} }

    it 'renders the requested metric' do
      action
      expect(json['id']).to eq metric.id
    end
  end
end
